<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';

const route = useRoute();
const { t } = useI18n();
const accountId = computed(() => route.params.accountId);

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
  {
    name: t('CONTACTS_LAYOUT.HEADER.SUB_NAV.COMPANIES'),
    routeName: 'contacts_dashboard_companies',
    path: `/app/accounts/${accountId.value}/contacts/companies`,
  },
  {
    name: t('SIDEBAR.SETTINGS'),
    routeName: 'attributes_list',
    path: `/app/accounts/${accountId.value}/settings/custom-attributes/list`,
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
</script>

<template>
  <div class="m-0 flex h-full flex-1 flex-col overflow-hidden bg-n-background">
    <!-- Sub-navigation Bar -->
    <div
      class="flex shrink-0 items-center justify-between border-b border-n-weak bg-n-background px-6 py-3"
    >
      <div class="flex items-center gap-6">
        <router-link
          v-for="tab in tabs"
          :key="tab.routeName"
          :to="tab.path"
          class="relative px-1 py-1.5 text-sm font-medium transition-colors hover:text-n-slate-12"
          :class="
            isActive(tab) ? 'font-semibold text-n-slate-12' : 'text-n-slate-11'
          "
        >
          {{ tab.name }}
          <span
            v-if="isActive(tab)"
            class="absolute bottom-0 left-0 right-0 h-0.5 rounded-full bg-n-brand"
          />
        </router-link>
      </div>
    </div>

    <!-- Page Content -->
    <div class="flex-1 overflow-auto">
      <router-view v-slot="{ Component }">
        <keep-alive>
          <component :is="Component" />
        </keep-alive>
      </router-view>
    </div>
  </div>
</template>
