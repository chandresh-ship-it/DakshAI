<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { picoSearch } from '@scmmishra/pico-search';
import { useAlert } from 'dashboard/composables';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

import AddCanned from './AddCanned.vue';
import EditCanned from './EditCanned.vue';
import {
  RelayButton,
  RelayInput,
} from 'dashboard/components-next/relay';

defineOptions({
  name: 'CannedResponseSettings',
});

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();
const { getPlainText } = useMessageFormatter();

const showAddPopup = ref(false);
const loading = ref({});
const showEditPopup = ref(false);
const showDeleteConfirmationPopup = ref(false);
const activeResponse = ref({});
const cannedResponseAPI = ref({ message: '' });

const sortOrder = ref('asc');
const searchQuery = ref('');

const records = computed(() =>
  getters.getSortedCannedResponses.value(sortOrder.value)
);

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return records.value;
  return picoSearch(records.value, query, [
    { name: 'short_code', weight: 4 },
    'content',
  ]);
});

const uiFlags = computed(() => getters.getUIFlags.value);

const deleteConfirmText = computed(
  () =>
    `${t('CANNED_MGMT.DELETE.CONFIRM.YES')} ${activeResponse.value.short_code}`
);

const deleteRejectText = computed(
  () =>
    `${t('CANNED_MGMT.DELETE.CONFIRM.NO')} ${activeResponse.value.short_code}`
);

const deleteMessage = computed(() => {
  return ` ${activeResponse.value.short_code} ? `;
});

const toggleSort = () => {
  sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
};

const fetchCannedResponses = async () => {
  try {
    await store.dispatch('getCannedResponse');
  } catch (error) {
    // Ignore Error
  }
};

onMounted(() => {
  fetchCannedResponses();
});

const showAlertMessage = message => {
  loading.value[activeResponse.value.id] = false;
  activeResponse.value = {};
  cannedResponseAPI.value.message = message;
  useAlert(message);
};

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = response => {
  showEditPopup.value = true;
  activeResponse.value = response;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
};

const openDeletePopup = response => {
  showDeleteConfirmationPopup.value = true;
  activeResponse.value = response;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const deleteCannedResponse = async id => {
  try {
    await store.dispatch('deleteCannedResponse', id);
    showAlertMessage(t('CANNED_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('CANNED_MGMT.DELETE.API.ERROR_MESSAGE');
    showAlertMessage(errorMessage);
  }
};

const confirmDeletion = () => {
  loading.value[activeResponse.value.id] = true;
  closeDeletePopup();
  deleteCannedResponse(activeResponse.value.id);
};
</script>

<template>
  <div class="px-8 pt-6 pb-12 flex flex-col gap-6 max-w-[1200px]">
    <!-- Main Card Container -->
    <div
      class="bg-card border border-border/80 rounded-2xl p-6 shadow-xs flex flex-col gap-6"
    >
      <!-- Header Section -->
      <div
        class="flex flex-col sm:flex-row sm:items-start justify-between gap-4"
      >
        <div class="flex flex-col">
          <h1 class="text-xl font-semibold tracking-tight text-foreground">
            {{ $t('CANNED_MGMT.HEADER', 'Quick Replies') }}
          </h1>
          <p class="mt-1 text-sm text-muted-foreground max-w-2xl leading-relaxed">
            {{
              $t(
                'CANNED_MGMT.DESCRIPTION',
                'Quick Replies are pre-written templates that help you quickly respond to a conversation. Agents can type the \'/\' character followed by the shortcode to insert a quick reply during a conversation.'
              )
            }}
          </p>
        </div>
        <RelayButton
          size="sm"
          class="shrink-0 shadow-xs"
          @click="openAddPopup"
        >
          <span class="i-lucide-plus size-4 mr-1.5" />
          {{ $t('CANNED_MGMT.HEADER_BTN_TXT', 'Add reply') }}
        </RelayButton>
      </div>

      <!-- Search Bar & Counter Bar -->
      <div
        class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-muted/20 border border-border/60 rounded-xl p-3"
      >
        <div class="relative flex-1 max-w-md">
          <span
            class="i-lucide-search absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground/60"
          />
          <RelayInput
            v-model="searchQuery"
            type="text"
            :placeholder="
              $t('CANNED_MGMT.SEARCH_PLACEHOLDER', 'Search quick reply...')
            "
            class-name="h-9 pl-9 pr-4 text-sm bg-background border-border/80 focus-visible:ring-1 focus-visible:ring-primary/30"
          />
        </div>
        <div class="text-xs font-medium text-muted-foreground px-1 shrink-0">
          {{ filteredRecords.length }}
          {{ $t('CANNED_MGMT.COUNT_SUFFIX', 'quick replies') }}
        </div>
      </div>

      <!-- Table Section -->
      <div
        class="w-full border border-border/60 rounded-xl overflow-hidden bg-card"
      >
        <div v-if="uiFlags.fetchingList" class="p-8 text-center text-sm text-muted-foreground">
          <span class="i-lucide-loader-2 size-5 animate-spin mx-auto mb-2 text-primary" />
          <p>{{ $t('CANNED_MGMT.LOADING', 'Loading quick replies...') }}</p>
        </div>

        <div
          v-else-if="!filteredRecords.length"
          class="p-12 text-center text-sm text-muted-foreground"
        >
          <span class="i-lucide-message-square-off size-8 mx-auto mb-3 opacity-40" />
          <p class="font-medium text-foreground">
            {{
              searchQuery
                ? $t('CANNED_MGMT.NO_RESULTS', 'No matching quick replies found')
                : $t('CANNED_MGMT.LIST.404', 'No quick replies available')
            }}
          </p>
        </div>

        <table v-else class="w-full text-left border-collapse text-[13.5px]">
          <thead>
            <tr
              class="border-b border-border/60 bg-muted/30 text-[11px] font-semibold text-muted-foreground uppercase tracking-wider"
            >
              <th class="py-3 px-5 w-48">
                <button
                  class="flex items-center gap-1.5 font-semibold text-muted-foreground hover:text-foreground transition-colors cursor-pointer"
                  @click="toggleSort"
                >
                  <span>{{ $t('CANNED_MGMT.LIST.TABLE_HEADER.SHORT_CODE', 'SHORT CODE') }}</span>
                  <span
                    class="i-lucide-arrow-up-down size-3.5 opacity-60"
                  />
                </button>
              </th>
              <th class="py-3 px-5">
                {{ $t('CANNED_MGMT.LIST.TABLE_HEADER.CONTENT', 'MESSAGE') }}
              </th>
              <th class="py-3 px-5 text-right w-24">
                {{ $t('CANNED_MGMT.LIST.TABLE_HEADER.ACTIONS', 'ACTIONS') }}
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-border/50">
            <tr
              v-for="cannedItem in filteredRecords"
              :key="cannedItem.id || cannedItem.short_code"
              class="group hover:bg-muted/30 transition-colors"
            >
              <!-- Shortcode Badge Column -->
              <td class="py-3.5 px-5 font-medium align-top">
                <div
                  class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-primary/10 text-primary border border-primary/20 text-xs font-mono font-medium"
                >
                  <span class="i-lucide-terminal size-3 opacity-70" />
                  {{ cannedItem.short_code }}
                </div>
              </td>

              <!-- Message Content Column -->
              <td class="py-3.5 px-5 text-foreground leading-relaxed align-top">
                <p class="line-clamp-3">
                  {{ getPlainText(cannedItem.content) }}
                </p>
              </td>

              <!-- Actions Column -->
              <td class="py-3.5 px-5 text-right align-top">
                <div class="flex items-center justify-end gap-1">
                  <RelayButton
                    v-tooltip.top="$t('CANNED_MGMT.EDIT.BUTTON_TEXT', 'Edit')"
                    variant="ghost"
                    size="icon"
                    class="size-8 text-muted-foreground hover:text-foreground"
                    @click="openEditPopup(cannedItem)"
                  >
                    <span class="i-lucide-pencil size-3.5" />
                  </RelayButton>
                  <RelayButton
                    v-tooltip.top="$t('CANNED_MGMT.DELETE.BUTTON_TEXT', 'Delete')"
                    variant="ghost"
                    size="icon"
                    class="size-8 text-muted-foreground hover:text-destructive"
                    :disabled="loading[cannedItem.id]"
                    @click="openDeletePopup(cannedItem)"
                  >
                    <span class="i-lucide-trash-2 size-3.5" />
                  </RelayButton>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Modals -->
    <woot-modal v-model:show="showAddPopup" :on-close="hideAddPopup">
      <AddCanned :on-close="hideAddPopup" />
    </woot-modal>

    <woot-modal v-model:show="showEditPopup" :on-close="hideEditPopup">
      <EditCanned
        v-if="showEditPopup"
        :id="activeResponse.id"
        :edshort-code="activeResponse.short_code"
        :edcontent="activeResponse.content"
        :on-close="hideEditPopup"
      />
    </woot-modal>

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('CANNED_MGMT.DELETE.CONFIRM.TITLE')"
      :message="$t('CANNED_MGMT.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />
  </div>
</template>
