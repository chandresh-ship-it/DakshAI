<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';

const route = useRoute();
const accountId = computed(() => route.params.accountId);

const tabs = computed(() => [
  {
    name: 'Contacts',
    routeName: 'contacts_dashboard_index',
    path: `/app/accounts/${accountId.value}/contacts`,
  },
  {
    name: 'Bulk Actions',
    routeName: 'contacts_dashboard_bulk_actions',
    path: `/app/accounts/${accountId.value}/contacts/bulk-actions`,
  },
  {
    name: 'Tasks',
    routeName: 'contacts_dashboard_tasks',
    path: `/app/accounts/${accountId.value}/contacts/tasks`,
  },
  {
    name: 'Companies',
    routeName: 'contacts_dashboard_companies',
    path: `/app/accounts/${accountId.value}/contacts/companies`,
  },
  {
    name: 'Settings',
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
  <div class="flex flex-col flex-1 h-full m-0 overflow-hidden bg-n-surface-1">
    <!-- Sub-navigation Bar -->
    <div
      class="flex items-center justify-between border-b border-n-slate-4 bg-n-surface-2 px-6 py-3 shrink-0"
    >
      <div class="flex items-center gap-6">
        <router-link
          v-for="tab in tabs"
          :key="tab.name"
          :to="tab.path"
          class="text-sm font-medium transition-colors hover:text-n-slate-12 px-1 py-1.5 relative"
          :class="
            isActive(tab) ? 'text-n-slate-12 font-semibold' : 'text-n-slate-9'
          "
        >
          {{ tab.name }}
          <span
            v-if="isActive(tab)"
            class="absolute bottom-0 left-0 right-0 h-0.5 bg-n-brand rounded-full"
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
