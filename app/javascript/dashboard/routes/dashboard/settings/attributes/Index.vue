<script setup>
import { computed, nextTick, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { picoSearch } from '@scmmishra/pico-search';
import {
  useStoreGetters,
  useStore,
  useMapGetter,
} from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';
import AddAttribute from './AddAttribute.vue';
import EditAttribute from './EditAttribute.vue';
import AttributeRow from './AttributeRow.vue';

defineOptions({
  name: 'CustomAttributeSettings',
});

const { t } = useI18n();
const getters = useStoreGetters();
const store = useStore();
const { currentAccount } = useAccount();
const inboxes = useMapGetter('inboxes/getInboxes');

const selectedTabIndex = ref(0);
const searchQuery = ref('');
const selectedAttribute = ref({});
const showAddPopup = ref(false);
const showEditPopup = ref(false);
const addDialogRef = ref(null);
const editDialogRef = ref(null);
const deleteDialogRef = ref(null);
const loading = ref({});

const attributeModels = ['conversation_attribute', 'contact_attribute'];
const uiFlags = computed(() => getters['attributes/getUIFlags'].value);

const tabs = computed(() => [
  {
    key: 0,
    name: t('ATTRIBUTES_MGMT.TABS.CONVERSATION', 'Conversation'),
  },
  {
    key: 1,
    name: t('ATTRIBUTES_MGMT.TABS.CONTACT', 'Contact'),
  },
]);

const attributeModel = computed(
  () => attributeModels[selectedTabIndex.value] || 'conversation_attribute'
);

const attributes = computed(() =>
  getters['attributes/getAttributesByModel'].value(attributeModel.value)
);

const requiredAttributeKeys = computed(
  () => currentAccount.value?.settings?.conversation_required_attributes || []
);

const hasPreChatBadge = attribute =>
  (inboxes.value || []).some(inbox => {
    const fields =
      inbox?.pre_chat_form_options?.pre_chat_fields ||
      inbox?.channel?.pre_chat_form_options?.pre_chat_fields ||
      [];
    return fields.some(field => field.name === attribute.attribute_key);
  });

const buildBadges = attribute => {
  const badges = [];
  if (hasPreChatBadge(attribute)) {
    badges.push({ type: 'pre-chat' });
  }
  if (
    attribute.attribute_model === 'conversation_attribute' &&
    requiredAttributeKeys.value.includes(attribute.attribute_key)
  ) {
    badges.push({ type: 'resolution' });
  }
  return badges;
};

const derivedAttributes = computed(() =>
  attributes.value.map(attribute => ({
    ...attribute,
    label: attribute.attribute_display_name,
    type: attribute.attribute_display_type,
    value: attribute.attribute_key,
    badges: buildBadges(attribute),
  }))
);

const filteredAttributes = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return derivedAttributes.value;
  return picoSearch(derivedAttributes.value, query, [
    'attribute_display_name',
    'attribute_key',
    'attribute_description',
  ]);
});

const emptyMessage = computed(() =>
  searchQuery.value.trim()
    ? t('ATTRIBUTES_MGMT.NO_RESULTS', 'No attributes found matching your search')
    : t('ATTRIBUTES_MGMT.LIST.EMPTY_RESULT.404', 'There are no custom attributes created')
);

const selectedAttributeName = computed(
  () => selectedAttribute.value?.attribute_display_name || ''
);

onMounted(() => {
  store.dispatch('attributes/get');
});

const onClickTabChange = key => {
  selectedTabIndex.value = key;
  searchQuery.value = '';
};

const openAddPopup = async () => {
  showAddPopup.value = true;
  await nextTick();
  addDialogRef.value?.open();
};

const hideAddPopup = () => {
  showAddPopup.value = false;
  addDialogRef.value?.close();
};

const handleEditAttribute = async attribute => {
  selectedAttribute.value = attribute;
  showEditPopup.value = true;
  await nextTick();
  editDialogRef.value?.open();
};

const hideEditPopup = () => {
  showEditPopup.value = false;
  selectedAttribute.value = {};
  editDialogRef.value?.close();
};

const handleDeleteAttribute = async attribute => {
  selectedAttribute.value = attribute;
  await nextTick();
  deleteDialogRef.value?.open();
};

const confirmDeleteAttribute = async () => {
  const id = selectedAttribute.value.id;
  loading.value[id] = true;
  try {
    await store.dispatch('attributes/delete', id);
    useAlert(t('ATTRIBUTES_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(error?.message || t('ATTRIBUTES_MGMT.DELETE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[id] = false;
    selectedAttribute.value = {};
    deleteDialogRef.value?.close();
  }
};
</script>

<template>
  <div class="px-8 pt-6 pb-12 flex flex-col gap-6 max-w-[1200px]">
    <!-- Main Card Container -->
    <div
      class="bg-card border border-border/80 rounded-2xl p-6 shadow-xs flex flex-col gap-6"
    >
      <!-- Header Section -->
      <div class="flex flex-col">
        <h1 class="text-xl font-semibold tracking-tight text-foreground">
          {{ $t('ATTRIBUTES_MGMT.HEADER', 'Custom Attributes') }}
        </h1>
        <p class="mt-1 text-sm text-muted-foreground max-w-3xl leading-relaxed">
          {{
            $t(
              'ATTRIBUTES_MGMT.DESCRIPTION',
              'A custom attribute tracks additional details about your contacts, companies, or conversations—such as the subscription plan or the date of their first purchase. You can add different types of custom attributes, such as text, lists, or numbers, to capture the specific information you need.'
            )
          }}
        </p>
      </div>

      <!-- Controls Bar: Tabs, Search & Add Action -->
      <div
        class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-muted/20 border border-border/60 rounded-xl p-3"
      >
        <div class="flex flex-col sm:flex-row sm:items-center gap-3 flex-1">
          <!-- Tab Selector Pills -->
          <div
            class="flex items-center rounded-xl bg-muted/40 p-1 border border-border/60 shrink-0"
            role="tablist"
          >
            <button
              v-for="tab in tabs"
              :key="tab.key"
              type="button"
              role="tab"
              :aria-selected="selectedTabIndex === tab.key"
              class="px-4 py-1.5 rounded-lg text-xs font-medium transition-all cursor-pointer"
              :class="
                selectedTabIndex === tab.key
                  ? 'bg-primary/20 text-primary border border-primary/30 font-semibold shadow-2xs'
                  : 'bg-transparent text-muted-foreground hover:text-foreground'
              "
              @click="onClickTabChange(tab.key)"
            >
              {{ tab.name }}
            </button>
          </div>

          <!-- Search Input Box -->
          <div class="relative flex-1 max-w-md">
            <span
              class="i-lucide-search absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground/60"
            />
            <RelayInput
              v-model="searchQuery"
              type="text"
              :placeholder="
                $t('ATTRIBUTES_MGMT.SEARCH_PLACEHOLDER', 'Search attributes...')
              "
              class-name="h-9 pl-9 pr-4 text-sm bg-background border-border/80 focus-visible:ring-1 focus-visible:ring-primary/30"
            />
          </div>
        </div>

        <!-- Add Button -->
        <RelayButton
          size="sm"
          class="shrink-0 shadow-xs"
          @click="openAddPopup"
        >
          <span class="i-lucide-plus size-4 mr-1.5" />
          {{ $t('ATTRIBUTES_MGMT.HEADER_BTN_TXT', 'Add Custom Attribute') }}
        </RelayButton>
      </div>

      <!-- Attributes List Container -->
      <div v-if="uiFlags.isFetching" class="p-12 text-center text-sm text-muted-foreground">
        <span class="i-lucide-loader-2 size-5 animate-spin mx-auto mb-2 text-primary" />
        <p>{{ $t('ATTRIBUTES_MGMT.LOADING', 'Fetching custom attributes...') }}</p>
      </div>

      <div
        v-else-if="!filteredAttributes.length"
        class="p-12 text-center text-sm text-muted-foreground border border-border/60 rounded-xl bg-card"
      >
        <span class="i-lucide-layers-slash size-8 mx-auto mb-3 opacity-40" />
        <p class="font-medium text-foreground">
          {{ emptyMessage }}
        </p>
      </div>

      <div v-else class="flex flex-col gap-3">
        <AttributeRow
          v-for="attribute in filteredAttributes"
          :key="attribute.id"
          :attribute="attribute"
          :badges="attribute.badges"
          :loading="loading[attribute.id]"
          @edit="handleEditAttribute"
          @delete="handleDeleteAttribute"
        />
      </div>
    </div>

    <!-- Modals -->
    <Dialog
      ref="addDialogRef"
      type="edit"
      title=""
      width="lg"
      :show-cancel-button="false"
      :show-confirm-button="false"
      overflow-y-auto
      @close="hideAddPopup"
    >
      <AddAttribute
        v-if="showAddPopup"
        :on-close="hideAddPopup"
        :selected-attribute-model-tab="selectedTabIndex"
      />
    </Dialog>

    <Dialog
      ref="editDialogRef"
      type="edit"
      title=""
      width="lg"
      :show-cancel-button="false"
      :show-confirm-button="false"
      overflow-y-auto
      @close="hideEditPopup"
    >
      <EditAttribute
        v-if="showEditPopup"
        :selected-attribute="selectedAttribute"
        @close="hideEditPopup"
      />
    </Dialog>

    <Dialog
      ref="deleteDialogRef"
      type="alert"
      :title="
        t('ATTRIBUTES_MGMT.DELETE.CONFIRM.TITLE', {
          attributeName: selectedAttributeName,
        })
      "
      :description="t('ATTRIBUTES_MGMT.DELETE.CONFIRM.MESSAGE')"
      :confirm-button-label="`${t('ATTRIBUTES_MGMT.DELETE.CONFIRM.YES')}${selectedAttributeName}`"
      :cancel-button-label="t('ATTRIBUTES_MGMT.DELETE.CONFIRM.NO')"
      :is-loading="uiFlags.isDeleting"
      @confirm="confirmDeleteAttribute"
      @close="selectedAttribute = {}"
    />
  </div>
</template>
