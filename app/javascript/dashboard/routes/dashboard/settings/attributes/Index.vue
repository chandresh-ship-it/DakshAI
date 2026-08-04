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

import SettingsLayout from '../SettingsLayout.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';
import AddAttribute from './AddAttribute.vue';
import EditAttribute from './EditAttribute.vue';
import AttributeRow from './AttributeRow.vue';

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
    name: t('ATTRIBUTES_MGMT.TABS.CONVERSATION'),
  },
  {
    key: 1,
    name: t('ATTRIBUTES_MGMT.TABS.CONTACT'),
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
    ? t('ATTRIBUTES_MGMT.NO_RESULTS')
    : t('ATTRIBUTES_MGMT.LIST.EMPTY_RESULT.404')
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
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="t('ATTRIBUTES_MGMT.LOADING')"
    :no-records-found="false"
  >
    <template #body>
      <div class="space-y-6">
        <div>
          <h2 class="text-base font-medium text-foreground">
            {{ t('ATTRIBUTES_MGMT.HEADER') }}
          </h2>
          <p
            class="mt-1.5 max-w-4xl text-[13.5px] leading-relaxed text-muted-foreground"
          >
            {{ t('ATTRIBUTES_MGMT.DESCRIPTION') }}
          </p>
        </div>

        <div
          class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
        >
          <div class="flex flex-col gap-4 sm:flex-row sm:items-center">
            <div
              class="flex items-center rounded-full border border-border/60 bg-card p-1 shadow-sm"
              role="tablist"
            >
              <button
                v-for="tab in tabs"
                :key="tab.key"
                type="button"
                role="tab"
                :aria-selected="selectedTabIndex === tab.key"
                class="rounded-full px-4 py-1.5 text-[13.5px] font-medium transition-all"
                :class="
                  selectedTabIndex === tab.key
                    ? 'bg-primary/10 text-primary shadow-none'
                    : 'bg-transparent text-muted-foreground hover:text-foreground'
                "
                @click="onClickTabChange(tab.key)"
              >
                {{ tab.name }}
              </button>
            </div>

            <div class="relative w-full max-w-xs">
              <Icon
                icon="i-lucide-search"
                class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
              />
              <RelayInput
                v-model="searchQuery"
                type="search"
                :placeholder="t('ATTRIBUTES_MGMT.SEARCH_PLACEHOLDER')"
                class-name="h-9 border-border bg-card pl-9 text-[13.5px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30"
              />
            </div>
          </div>

          <RelayButton
            class="h-9 shrink-0 px-5 font-medium shadow-sm"
            @click="openAddPopup"
          >
            {{ t('ATTRIBUTES_MGMT.HEADER_BTN_TXT') }}
          </RelayButton>
        </div>

        <div
          v-if="!filteredAttributes.length"
          class="flex flex-col items-center justify-center py-32 text-center"
        >
          <p class="text-[14px] font-medium text-foreground">
            {{ emptyMessage }}
          </p>
        </div>

        <div
          v-else
          class="overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
        >
          <div class="divide-y divide-border/40">
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
      </div>
    </template>

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
  </SettingsLayout>
</template>
