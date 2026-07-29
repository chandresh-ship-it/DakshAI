<script setup>
import { computed } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import {
  DropdownContainer,
  DropdownBody,
  DropdownSeparator,
  DropdownItem,
} from 'next/dropdown-menu/base';

const emit = defineEmits(['showCreateAccountModal']);

const { t } = useI18n();
const { accountId, currentAccount } = useAccount();
const currentUser = useMapGetter('getCurrentUser');
const globalConfig = useMapGetter('globalConfig/get');

const isAdmin = computed(() => {
  if (currentUser.value.type === 'SuperAdmin') return true;
  const current = (currentUser.value.accounts || []).find(
    a => a.id === accountId.value
  );
  return current?.role === 'administrator';
});

const isSubAccount = computed(() => {
  const current = (currentUser.value.accounts || []).find(
    a => a.id === accountId.value
  );
  return !!current?.parent_id;
});

const canCreateWorkspace = computed(
  () =>
    globalConfig.value.createNewAccountFromDashboard &&
    isAdmin.value &&
    !isSubAccount.value
);

const brandInitial = computed(() => {
  const name =
    currentAccount.value?.name || globalConfig.value?.installationName || 'N';
  return name.charAt(0).toUpperCase();
});

const brandSubtitle = computed(() => t('SIDEBAR.ENTERPRISE_EDITION'));

const sortedAccounts = computed(() => {
  const accounts = currentUser.value.accounts || [];
  const parents = accounts
    .filter(a => !a.parent_id)
    .sort((a, b) => a.name.localeCompare(b.name));
  const result = [];

  parents.forEach(parent => {
    result.push(parent);
    accounts
      .filter(a => a.parent_id === parent.id)
      .sort((a, b) => a.name.localeCompare(b.name))
      .forEach(child => {
        result.push({ ...child, isChild: true });
      });
  });

  const childIds = result.map(a => a.id);
  accounts
    .filter(a => a.parent_id && !childIds.includes(a.id))
    .sort((a, b) => a.name.localeCompare(b.name))
    .forEach(orphan => result.push(orphan));

  return result;
});

const availableWorkspaces = computed(() =>
  sortedAccounts.value.filter(account => account.id !== accountId.value)
);

const accountInitial = name => (name || 'W').charAt(0).toUpperCase();

const onChangeAccount = newId => {
  window.location.href = `/app/accounts/${newId}/dashboard`;
};

const onAddWorkspace = () => {
  emit('showCreateAccountModal');
};
</script>

<template>
  <DropdownContainer>
    <template #trigger="{ toggle, isOpen }">
      <button
        type="button"
        class="flex items-center gap-2 rounded-full border border-n-weak bg-n-background py-1 pl-1 pr-2 text-left text-sm shadow-sm transition-colors hover:bg-n-alpha-2 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-n-brand"
        :class="{ 'bg-n-alpha-2': isOpen }"
        @click="toggle"
      >
        <span
          class="flex size-8 shrink-0 items-center justify-center rounded-full bg-n-brand text-sm font-bold text-white"
        >
          {{ brandInitial }}
        </span>
        <span class="hidden min-w-0 items-center gap-1.5 md:flex">
          <span class="max-w-28 truncate font-medium text-n-slate-12">
            {{ currentAccount.name }}
          </span>
          <span
            class="i-lucide-chevron-down size-3.5 shrink-0 text-n-slate-11"
          />
        </span>
      </button>
    </template>

    <DropdownBody class="top-full z-50 mt-1 w-64 p-2 ltr:right-0 rtl:left-0">
      <div class="mb-2 rounded-md bg-n-alpha-2 px-2 py-2">
        <div class="flex items-center gap-3">
          <span
            class="flex size-8 shrink-0 items-center justify-center rounded-full bg-n-brand text-sm font-bold text-white"
          >
            {{ brandInitial }}
          </span>
          <div class="grid min-w-0 flex-1 text-left text-sm leading-tight">
            <span class="truncate font-semibold text-n-slate-12">
              {{ currentAccount.name }}
            </span>
            <span class="truncate text-xs font-normal text-n-slate-11">
              {{ brandSubtitle }}
            </span>
          </div>
        </div>
      </div>

      <DropdownSeparator />

      <p class="px-2 pb-2 pt-2 text-xs font-semibold text-n-slate-11">
        {{ t('SIDEBAR_ITEMS.AVAILABLE_WORKSPACES') }}
      </p>

      <div
        v-if="availableWorkspaces.length"
        class="mb-1 max-h-48 overflow-y-auto"
      >
        <DropdownItem
          v-for="account in availableWorkspaces"
          :id="`workspace-${account.id}`"
          :key="account.id"
          class="cursor-pointer rounded-md p-2"
          @click="onChangeAccount(account.id)"
        >
          <template #label>
            <div class="flex w-full items-center gap-2">
              <span
                class="flex size-6 shrink-0 items-center justify-center rounded-full bg-n-alpha-2 text-xs font-bold text-n-slate-12"
              >
                {{ accountInitial(account.name) }}
              </span>
              <span
                class="truncate text-sm text-n-slate-12"
                :class="{ 'pl-2 text-n-slate-11': account.isChild }"
              >
                {{ account.name }}
              </span>
            </div>
          </template>
        </DropdownItem>
      </div>
      <p v-else class="px-2 pb-2 text-xs text-n-slate-11">
        {{ t('SIDEBAR_ITEMS.NO_OTHER_WORKSPACES') }}
      </p>

      <DropdownSeparator />

      <DropdownItem
        v-if="canCreateWorkspace"
        class="cursor-pointer rounded-md p-2 text-n-slate-11"
        :label="t('SIDEBAR_ITEMS.ADD_NEW_WORKSPACE')"
        icon="i-lucide-plus"
        :click="onAddWorkspace"
      />

      <DropdownSeparator v-if="canCreateWorkspace" />

      <DropdownItem
        class="cursor-pointer rounded-md p-2 text-n-slate-11"
        :label="t('SIDEBAR_ITEMS.PROFILE_SETTING')"
        icon="i-lucide-user"
        :link="{ name: 'profile_settings_index' }"
      />
    </DropdownBody>
  </DropdownContainer>
</template>
