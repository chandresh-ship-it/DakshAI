<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onBeforeMount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { picoSearch } from '@scmmishra/pico-search';

import AddLabel from './AddLabel.vue';
import EditLabel from './EditLabel.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const loading = ref({});
const showAddPopup = ref(false);
const showEditPopup = ref(false);
const showDeleteConfirmationPopup = ref(false);
const selectedLabel = ref({});
const searchQuery = ref('');

const records = computed(() => getters['labels/getLabels'].value);

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return records.value;
  return picoSearch(records.value, query, [
    { name: 'title', weight: 4 },
    'description',
  ]);
});
const uiFlags = computed(() => getters['labels/getUIFlags'].value);

const deleteMessage = computed(() => ` ${selectedLabel.value.title}?`);

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = response => {
  showEditPopup.value = true;
  selectedLabel.value = response;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
};

const openDeletePopup = response => {
  showDeleteConfirmationPopup.value = true;
  selectedLabel.value = response;
};
const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const deleteLabel = async id => {
  try {
    await store.dispatch('labels/delete', id);
    useAlert(t('LABEL_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('LABEL_MGMT.DELETE.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  } finally {
    loading.value[selectedLabel.value.id] = false;
  }
};

const confirmDeletion = () => {
  loading.value[selectedLabel.value.id] = true;
  closeDeletePopup();
  deleteLabel(selectedLabel.value.id);
};

onBeforeMount(() => {
  store.dispatch('labels/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('LABEL_MGMT.LOADING')"
    :no-records-found="!records.length"
    :no-records-message="$t('LABEL_MGMT.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('LABEL_MGMT.HEADER')"
        :description="$t('LABEL_MGMT.DESCRIPTION')"
        :link-text="$t('LABEL_MGMT.LEARN_MORE')"
        :search-placeholder="$t('LABEL_MGMT.SEARCH_PLACEHOLDER')"
        feature-name="labels"
      >
        <template v-if="records?.length" #count>
          <span class="text-sm text-muted-foreground">
            {{ $t('LABEL_MGMT.COUNT', { n: records.length }) }}
          </span>
        </template>
        <template #actions>
          <RelayButton size="sm" @click="openAddPopup">
            {{ $t('LABEL_MGMT.HEADER_BTN_TXT') }}
          </RelayButton>
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div
        class="overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
      >
        <div v-if="!filteredRecords.length && searchQuery" class="py-20">
          <p class="text-center text-sm text-muted-foreground">
            {{ $t('LABEL_MGMT.NO_RESULTS') }}
          </p>
        </div>
        <div v-else class="overflow-x-auto">
          <table class="w-full border-collapse text-left">
            <thead>
              <tr class="border-b border-border/40 bg-background">
                <th
                  class="w-64 px-6 py-3.5 text-[13px] font-medium text-muted-foreground"
                >
                  {{ $t('LABEL_MGMT.LIST.TABLE_HEADER.NAME') }}
                </th>
                <th
                  class="px-6 py-3.5 text-[13px] font-medium text-muted-foreground"
                >
                  {{ $t('LABEL_MGMT.LIST.TABLE_HEADER.DESCRIPTION') }}
                </th>
                <th
                  class="w-48 px-6 py-3.5 text-[13px] font-medium text-muted-foreground"
                >
                  {{ $t('LABEL_MGMT.LIST.TABLE_HEADER.COLOR') }}
                </th>
                <th
                  class="w-32 px-6 py-3.5 text-[13px] font-medium text-muted-foreground"
                >
                  {{ $t('LABEL_MGMT.LIST.TABLE_HEADER.ACTION') }}
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-border/40">
              <tr
                v-for="label in filteredRecords"
                :key="label.title"
                class="bg-card transition-colors hover:bg-muted/10"
              >
                <td class="px-6 py-4 text-[14px] font-medium text-foreground">
                  {{ label.title }}
                </td>
                <td class="px-6 py-4 text-[13px] text-muted-foreground">
                  {{ label.description }}
                </td>
                <td class="px-6 py-4">
                  <div class="flex items-center gap-2.5">
                    <div
                      class="size-[18px] rounded-sm shadow-xs"
                      :style="{ backgroundColor: label.color }"
                    />
                    <span
                      class="font-mono text-[13px] uppercase text-foreground"
                    >
                      {{ label.color }}
                    </span>
                  </div>
                </td>
                <td class="px-6 py-4">
                  <div
                    class="flex items-center gap-1.5 opacity-60 transition-opacity hover:opacity-100"
                  >
                    <RelayButton
                      v-tooltip.top="$t('LABEL_MGMT.FORM.EDIT')"
                      variant="ghost"
                      size="icon"
                      class="size-7 border border-transparent text-muted-foreground hover:border-border hover:bg-muted/50 hover:text-foreground"
                      :disabled="loading[label.id]"
                      @click="openEditPopup(label)"
                    >
                      <Icon icon="i-lucide-pencil" class="size-3.5" />
                    </RelayButton>
                    <RelayButton
                      v-tooltip.top="$t('LABEL_MGMT.FORM.DELETE')"
                      variant="ghost"
                      size="icon"
                      class="size-7 border border-transparent text-muted-foreground hover:border-red-100 hover:bg-red-50 hover:text-red-600"
                      :disabled="loading[label.id]"
                      @click="openDeletePopup(label)"
                    >
                      <Icon icon="i-lucide-trash-2" class="size-3.5" />
                    </RelayButton>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </template>

    <woot-modal v-model:show="showAddPopup" :on-close="hideAddPopup">
      <AddLabel @close="hideAddPopup" />
    </woot-modal>

    <woot-modal v-model:show="showEditPopup" :on-close="hideEditPopup">
      <EditLabel :selected-response="selectedLabel" @close="hideEditPopup" />
    </woot-modal>

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('LABEL_MGMT.DELETE.CONFIRM.TITLE')"
      :message="$t('LABEL_MGMT.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="$t('LABEL_MGMT.DELETE.CONFIRM.YES')"
      :reject-text="$t('LABEL_MGMT.DELETE.CONFIRM.NO')"
    />
  </SettingsLayout>
</template>
