<script setup>
import { useAlert } from 'dashboard/composables';
import { picoSearch } from '@scmmishra/pico-search';
import MacrosTableRow from './MacrosTableRow.vue';
import SettingsLayout from '../SettingsLayout.vue';
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import { useAdmin } from 'dashboard/composables/useAdmin';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();
const { isAdmin } = useAdmin();

const showDeleteConfirmationPopup = ref(false);
const selectedMacro = ref({});
const searchQuery = ref('');

const records = computed(() => getters['macros/getMacros'].value);
const uiFlags = computed(() => getters['macros/getUIFlags'].value);

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return records.value;
  return picoSearch(records.value, query, ['name']);
});

const deleteMessage = computed(() => ` ${selectedMacro.value.name}?`);

onMounted(() => {
  store.dispatch('macros/get');
});

const deleteMacro = async id => {
  try {
    await store.dispatch('macros/delete', id);
    useAlert(t('MACROS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('MACROS.DELETE.API.ERROR_MESSAGE'));
  }
};

const openDeletePopup = response => {
  showDeleteConfirmationPopup.value = true;
  selectedMacro.value = response;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const confirmDeletion = () => {
  closeDeletePopup();
  deleteMacro(selectedMacro.value.id);
};
</script>

<template>
  <SettingsLayout
    :no-records-message="$t('MACROS.LIST.404')"
    :no-records-found="!records.length"
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('MACROS.LOADING')"
    feature-name="macros"
  >
    <template #header>
      <div
        class="pb-6 border-b border-border/40 flex flex-col sm:flex-row sm:items-center justify-between gap-4"
      >
        <div>
          <h3 class="text-base font-semibold text-foreground">
            {{ $t('MACROS.HEADER') }}
          </h3>
          <p class="text-sm text-muted-foreground mt-1 max-w-3xl">
            {{ $t('MACROS.DESCRIPTION') }}
          </p>
        </div>
        <router-link :to="{ name: 'macros_new' }">
          <Button
            class="shrink-0 h-9 px-4 font-medium shadow-sm bg-primary hover:bg-primary/90 text-primary-foreground border-0 text-[13px]"
          >
            {{ $t('MACROS.HEADER_BTN_TXT') }}
          </Button>
        </router-link>
      </div>
    </template>
    <template #body>
      <!-- Toolbar -->
      <div
        class="flex items-center justify-between bg-card border border-border/60 p-2 rounded-xl shadow-sm mb-6 mt-4"
      >
        <div class="relative w-full max-w-md">
          <span
            class="i-lucide-search size-4 absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground block"
          />
          <input
            v-model="searchQuery"
            :placeholder="$t('MACROS.SEARCH_PLACEHOLDER')"
            class="pl-9 bg-background/50 border border-border/40 focus:border-border/80 shadow-none h-9 w-full text-[13.5px] rounded-lg outline-none focus-visible:ring-1 focus-visible:ring-primary/20 focus-visible:bg-background"
          />
        </div>
        <div
          class="px-4 text-[13px] font-medium text-muted-foreground shrink-0 border-l border-border/40"
        >
          {{ filteredRecords.length }}
          {{
            $t('MACROS.COUNT', { n: filteredRecords.length })
              .replace(/[0-9]/g, '')
              .trim()
          }}
        </div>
      </div>

      <!-- List View Table -->
      <div
        class="bg-card border border-border/60 rounded-xl shadow-sm overflow-hidden"
      >
        <div
          v-if="filteredRecords.length === 0"
          class="p-16 text-center flex flex-col items-center justify-center"
        >
          <div
            class="size-14 rounded-full bg-muted flex items-center justify-center mb-5"
          >
            <span class="i-lucide-wand-2 size-6 text-muted-foreground block" />
          </div>
          <h3 class="text-base font-medium text-foreground">
            {{ $t('MACROS.NO_RESULTS') }}
          </h3>
          <p class="text-[13.5px] text-muted-foreground mt-1">
            {{ $t('MACROS.LIST.404') }}
          </p>
        </div>

        <div v-else class="min-w-full">
          <!-- Table Header -->
          <div
            class="grid grid-cols-[1.5fr_1fr_1fr_1fr_100px] items-center px-6 py-3.5 border-b border-border/40 bg-muted/30"
          >
            <div
              class="text-[12px] font-medium text-muted-foreground uppercase tracking-wider"
            >
              {{ $t('MACROS.LIST.TABLE_HEADER.NAME') }}
            </div>
            <div
              class="text-[12px] font-medium text-muted-foreground uppercase tracking-wider"
            >
              {{ $t('MACROS.LIST.TABLE_HEADER.CREATED BY') }}
            </div>
            <div
              class="text-[12px] font-medium text-muted-foreground uppercase tracking-wider"
            >
              {{ $t('MACROS.LIST.TABLE_HEADER.LAST_UPDATED_BY') }}
            </div>
            <div
              class="text-[12px] font-medium text-muted-foreground uppercase tracking-wider"
            >
              {{ $t('MACROS.LIST.TABLE_HEADER.VISIBILITY') }}
            </div>
            <div
              class="text-[12px] font-medium text-muted-foreground uppercase tracking-wider text-right"
            >
              {{ $t('MACROS.LIST.TABLE_HEADER.ACTIONS') }}
            </div>
          </div>

          <!-- Table Body -->
          <div class="divide-y divide-border/40">
            <MacrosTableRow
              v-for="macro in filteredRecords"
              :key="macro.id"
              :macro="macro"
              :can-manage-public-macros="isAdmin"
              @delete="openDeletePopup(macro)"
            />
          </div>
        </div>
      </div>

      <woot-delete-modal
        v-model:show="showDeleteConfirmationPopup"
        :on-close="closeDeletePopup"
        :on-confirm="confirmDeletion"
        :title="$t('LABEL_MGMT.DELETE.CONFIRM.TITLE')"
        :message="$t('MACROS.DELETE.CONFIRM.MESSAGE')"
        :message-value="deleteMessage"
        :confirm-text="$t('MACROS.DELETE.CONFIRM.YES')"
        :reject-text="$t('MACROS.DELETE.CONFIRM.NO')"
      />
    </template>
  </SettingsLayout>
</template>
