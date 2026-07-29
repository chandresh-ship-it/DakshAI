<script setup>
import { ref, computed } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store.js';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { RelayButton } from 'dashboard/components-next/relay';
import BackButton from 'dashboard/components/widgets/BackButton.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Policy from 'dashboard/components/policy.vue';
import AssistantSwitcher from 'dashboard/components-next/captain/pageComponents/switcher/AssistantSwitcher.vue';
import CreateAssistantDialog from 'dashboard/components-next/captain/pageComponents/assistant/CreateAssistantDialog.vue';

const props = defineProps({
  currentPage: {
    type: Number,
    default: 1,
  },
  totalCount: {
    type: Number,
    default: 100,
  },
  itemsPerPage: {
    type: Number,
    default: 25,
  },
  headerTitle: {
    type: String,
    default: '',
  },
  backUrl: {
    type: [String, Object],
    default: '',
  },
  buttonPolicy: {
    type: Array,
    default: () => [],
  },
  buttonLabel: {
    type: String,
    default: '',
  },
  featureFlag: {
    type: String,
    default: '',
  },
  isFetching: {
    type: Boolean,
    default: false,
  },
  showKnowMore: {
    type: Boolean,
    default: true,
  },
  isEmpty: {
    type: Boolean,
    default: false,
  },
  showPaginationFooter: {
    type: Boolean,
    default: true,
  },
  showAssistantSwitcher: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['click', 'close', 'update:currentPage']);

const { t } = useI18n();

const route = useRoute();
const { shouldShowPaywall } = usePolicy();

const showAssistantSwitcherDropdown = ref(false);
const createAssistantDialogRef = ref(null);

const assistants = useMapGetter('captainAssistants/getRecords');
const uiFlags = useMapGetter('captainAssistants/getUIFlags');

const currentAssistantId = computed(() => route.params.assistantId);
const isFetchingAssistants = computed(() => uiFlags.value?.fetchingList);

const activeAssistantName = computed(() => {
  return (
    assistants.value?.find(
      assistant => assistant.id === Number(currentAssistantId.value)
    )?.name || t('CAPTAIN.ASSISTANT_SWITCHER.NEW_ASSISTANT')
  );
});

const showPaywall = computed(() => {
  return shouldShowPaywall(props.featureFlag);
});

const handleButtonClick = () => {
  emit('click');
};

const handlePageChange = event => {
  emit('update:currentPage', event);
};

const toggleAssistantSwitcher = () => {
  showAssistantSwitcherDropdown.value = !showAssistantSwitcherDropdown.value;
};

const handleCreateAssistant = () => {
  showAssistantSwitcherDropdown.value = false;
  createAssistantDialogRef.value.dialogRef.open();
};
</script>

<template>
  <section class="flex h-full w-full flex-col overflow-hidden bg-n-background">
    <header class="z-10 shrink-0 border-b border-n-weak bg-n-background px-6">
      <div class="mx-auto w-full max-w-5xl">
        <div
          class="flex min-h-14 w-full flex-col items-start justify-between gap-4 py-3 sm:flex-row sm:items-center"
        >
          <div class="flex items-center gap-3">
            <BackButton v-if="backUrl" :back-url="backUrl" />
            <div
              v-if="showAssistantSwitcher && !showPaywall"
              class="relative flex items-center"
            >
              <OnClickOutside @trigger="showAssistantSwitcherDropdown = false">
                <RelayButton
                  variant="outline"
                  size="sm"
                  class="h-8 max-w-[14rem] gap-1.5 rounded-lg border-n-weak bg-n-background px-2.5 text-n-slate-12 shadow-sm hover:bg-n-alpha-2"
                  :class="{ 'bg-n-alpha-2': showAssistantSwitcherDropdown }"
                  :disabled="isFetchingAssistants"
                  @click="toggleAssistantSwitcher"
                >
                  <span
                    v-if="isFetchingAssistants"
                    class="i-lucide-loader-circle size-3.5 shrink-0 animate-spin text-n-slate-11"
                  />
                  <span
                    v-else
                    class="i-lucide-brain-circuit size-3.5 shrink-0 text-n-brand"
                  />
                  <span class="min-w-0 truncate text-sm font-medium">
                    {{ activeAssistantName }}
                  </span>
                  <span
                    class="i-lucide-chevron-down size-3.5 shrink-0 text-n-slate-11"
                  />
                </RelayButton>

                <AssistantSwitcher
                  v-if="showAssistantSwitcherDropdown"
                  class="absolute ltr:left-0 rtl:right-0 top-9"
                  @close="showAssistantSwitcherDropdown = false"
                  @create-assistant="handleCreateAssistant"
                />
              </OnClickOutside>
            </div>
            <div class="flex items-center gap-3">
              <div
                v-if="showAssistantSwitcher && !showPaywall && headerTitle"
                class="h-4 w-0.5 rounded-2xl bg-n-weak"
              />
              <span
                v-if="headerTitle"
                class="text-base font-medium text-n-slate-12"
              >
                {{ headerTitle }}
              </span>
              <div v-if="showKnowMore" class="flex items-center gap-2">
                <div class="h-4 w-0.5 rounded-2xl bg-n-weak" />
                <slot name="knowMore" />
              </div>
            </div>
          </div>

          <div class="flex w-full items-center gap-3 sm:w-auto">
            <slot name="search" />
            <div
              v-if="!showPaywall && buttonLabel"
              v-on-clickaway="() => emit('close')"
              class="relative shrink-0 group/captain-button"
            >
              <Policy class="contents" :permissions="buttonPolicy">
                <RelayButton
                  class="h-9 shrink-0 group-hover/captain-button:brightness-110"
                  @click="handleButtonClick"
                >
                  <span class="i-lucide-plus size-4 mr-1.5" />
                  {{ buttonLabel }}
                </RelayButton>
              </Policy>
              <slot name="action" />
            </div>
          </div>
        </div>
        <slot name="subHeader" />
      </div>
    </header>
    <main class="flex-1 overflow-y-auto px-6">
      <div class="mx-auto h-full w-full max-w-5xl py-4">
        <slot v-if="!showPaywall" name="controls" />
        <div
          v-if="isFetching"
          class="flex items-center justify-center py-10 text-n-slate-11"
        >
          <Spinner />
        </div>
        <div v-else-if="showPaywall">
          <slot name="paywall" />
        </div>
        <div v-else-if="isEmpty">
          <slot name="emptyState" />
        </div>
        <slot v-else name="body" />
        <slot />
      </div>
    </main>
    <footer v-if="showPaginationFooter" class="sticky bottom-0 z-10">
      <PaginationFooter
        :current-page="currentPage"
        :total-items="totalCount"
        :items-per-page="itemsPerPage"
        class="max-w-[67rem]"
        @update:current-page="handlePageChange"
      />
    </footer>
    <CreateAssistantDialog ref="createAssistantDialogRef" type="create" />
  </section>
</template>
