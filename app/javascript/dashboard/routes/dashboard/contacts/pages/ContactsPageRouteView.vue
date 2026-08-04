<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { CONTACTS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import {
  DuplicateContactException,
  ExceptionWithMessage,
} from 'shared/helpers/CustomErrors';
import { usePolicy } from 'dashboard/composables/usePolicy';

import { RelayButton } from 'dashboard/components-next/relay';
import AddContactDrawer from 'dashboard/components-next/Contacts/Drawers/AddContactDrawer.vue';
import ContactImportDialog from 'dashboard/components-next/Contacts/ContactsForm/ContactImportDialog.vue';

const route = useRoute();
const { t } = useI18n();
const store = useStore();
const { checkPermissions } = usePolicy();

const addContactDrawerRef = ref(null);
const contactImportDialogRef = ref(null);

const accountId = computed(() => route.params.accountId);
const canManageContacts = computed(() =>
  checkPermissions(['administrator', 'contact_manage'])
);

const tabs = computed(() => [
  {
    name: t('CONTACTS_LAYOUT.HEADER.SUB_NAV.CONTACTS'),
    routeName: 'contacts_dashboard_index',
    path: `/app/accounts/${accountId.value}/contacts`,
  },
  {
    name: t('CONTACTS_LAYOUT.HEADER.SUB_NAV.BULK_ACTIONS'),
    routeName: 'contacts_dashboard_bulk_actions',
    path: `/app/accounts/${accountId.value}/contacts/bulk-actions`,
  },
  {
    name: t('CONTACTS_LAYOUT.HEADER.SUB_NAV.TASKS'),
    routeName: 'contacts_dashboard_tasks',
    path: `/app/accounts/${accountId.value}/contacts/tasks`,
  },
]);

const isActive = tab => {
  if (route.name === tab.routeName) return true;
  if (tab.routeName === 'contacts_dashboard_index') {
    return [
      'contacts_dashboard_segments_index',
      'contacts_dashboard_labels_index',
      'contacts_dashboard_active',
    ].includes(route.name);
  }
  return false;
};

const openCreateContact = () => addContactDrawerRef.value?.open();
const openImportContacts = () => contactImportDialogRef.value?.dialogRef.open();

const onCreate = async contact => {
  try {
    await store.dispatch('contacts/create', contact);
    addContactDrawerRef.value?.close();
    useAlert(
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION.SUCCESS_MESSAGE')
    );
  } catch (error) {
    const i18nPrefix = 'CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION';
    if (error instanceof DuplicateContactException) {
      if (error.data.includes('email')) {
        useAlert(t(`${i18nPrefix}.EMAIL_ADDRESS_DUPLICATE`));
      } else if (error.data.includes('phone_number')) {
        useAlert(t(`${i18nPrefix}.PHONE_NUMBER_DUPLICATE`));
      }
    } else if (error instanceof ExceptionWithMessage) {
      useAlert(error.data);
    } else {
      useAlert(t(`${i18nPrefix}.ERROR_MESSAGE`));
    }
  }
};

const onImport = async file => {
  try {
    await store.dispatch('contacts/import', file);
    contactImportDialogRef.value?.dialogRef.close();
    useAlert(
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.SUCCESS_MESSAGE')
    );
    useTrack(CONTACTS_EVENTS.IMPORT_SUCCESS);
  } catch (error) {
    useAlert(
      error.message ??
        t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.ERROR_MESSAGE')
    );
    useTrack(CONTACTS_EVENTS.IMPORT_FAILURE);
  }
};
</script>

<template>
  <div class="m-0 flex h-full flex-1 flex-col overflow-hidden bg-background">
    <header
      class="flex shrink-0 flex-col border-b border-border/40 px-6 pb-0 pt-6"
    >
      <div class="flex items-start justify-between gap-4">
        <div>
          <h1 class="text-base font-medium tracking-tight text-foreground">
            {{ t('CONTACTS_LAYOUT.HEADER.TITLE') }}
          </h1>
          <p class="mt-1 text-sm text-muted-foreground">
            {{ t('CONTACTS_LAYOUT.HEADER.DESCRIPTION') }}
          </p>
        </div>
        <div class="flex shrink-0 items-center gap-3">
          <RelayButton
            v-if="canManageContacts"
            variant="outline"
            class="hidden h-9 rounded-lg px-4 text-sm font-medium shadow-sm sm:inline-flex"
            @click="openImportContacts"
          >
            <span class="i-lucide-upload size-4" />
            {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.IMPORT') }}
          </RelayButton>
          <RelayButton
            class="h-9 rounded-lg px-4 text-sm font-medium shadow-sm"
            @click="openCreateContact"
          >
            <span class="i-lucide-plus size-4" />
            {{
              t('CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION.ADD_CONTACT')
            }}
          </RelayButton>
        </div>
      </div>

      <nav class="mt-6 flex items-center gap-6 overflow-x-auto" role="tablist">
        <router-link
          v-for="tab in tabs"
          :key="tab.routeName"
          :to="tab.path"
          role="tab"
          :aria-selected="isActive(tab)"
          class="relative shrink-0 border-b-2 px-1 pb-3 pt-2 text-sm font-medium transition-colors"
          :class="
            isActive(tab)
              ? 'border-primary text-foreground'
              : 'border-transparent text-muted-foreground hover:text-foreground'
          "
        >
          {{ tab.name }}
        </router-link>
      </nav>
    </header>

    <div class="flex-1 overflow-auto">
      <router-view v-slot="{ Component }">
        <keep-alive>
          <component :is="Component" />
        </keep-alive>
      </router-view>
    </div>

    <AddContactDrawer ref="addContactDrawerRef" @create="onCreate" />
    <ContactImportDialog ref="contactImportDialogRef" @import="onImport" />
  </div>
</template>
