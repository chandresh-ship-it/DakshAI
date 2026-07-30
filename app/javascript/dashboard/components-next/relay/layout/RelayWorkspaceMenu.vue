<script setup>
import { computed, ref } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';

const emit = defineEmits(['showCreateAccountModal']);

const { t } = useI18n();
const { accountId, currentAccount } = useAccount();
const currentUser = useMapGetter('getCurrentUser');
const globalConfig = useMapGetter('globalConfig/get');

const isOpen = ref(false);

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

const closeMenu = () => {
  isOpen.value = false;
};

const toggleMenu = () => {
  isOpen.value = !isOpen.value;
};

const onChangeAccount = newId => {
  closeMenu();
  window.location.href = `/app/accounts/${newId}/dashboard`;
};

const onAddWorkspace = () => {
  closeMenu();
  emit('showCreateAccountModal');
};
</script>

<template>
  <div v-on-click-outside="closeMenu" class="relative">
    <button
      type="button"
      class="flex items-center gap-2 rounded-full border border-input bg-background py-1 pl-1 pr-2 text-left text-sm shadow-xs transition-colors hover:border-transparent hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
      :class="{ 'bg-accent': isOpen }"
      :aria-expanded="isOpen"
      @click="toggleMenu"
    >
      <span
        class="flex size-8 shrink-0 items-center justify-center rounded-full bg-primary text-sm font-bold text-primary-foreground"
      >
        {{ brandInitial }}
      </span>
      <span class="hidden min-w-0 items-center gap-1.5 md:flex">
        <span class="max-w-28 truncate text-sm font-medium text-foreground">
          {{ currentAccount.name }}
        </span>
        <span
          class="i-lucide-chevron-down size-3.5 shrink-0 text-muted-foreground"
        />
      </span>
    </button>

    <div
      v-if="isOpen"
      class="absolute top-full z-50 mt-1 w-64 rounded-xl border border-border bg-popover p-2 text-popover-foreground shadow-sm ltr:right-0 rtl:left-0"
    >
      <div class="mb-2 rounded-md bg-muted px-2 py-2">
        <div class="flex items-center gap-3">
          <span
            class="flex size-8 shrink-0 items-center justify-center rounded-full bg-primary text-sm font-bold text-primary-foreground"
          >
            {{ brandInitial }}
          </span>
          <div class="grid min-w-0 flex-1 text-left text-sm leading-tight">
            <span class="truncate font-semibold text-foreground">
              {{ currentAccount.name }}
            </span>
            <span class="truncate text-xs font-normal text-muted-foreground">
              {{ brandSubtitle }}
            </span>
          </div>
        </div>
      </div>

      <div class="my-2 h-px bg-border" />

      <p class="px-2 pb-2 pt-1 text-xs font-semibold text-muted-foreground">
        {{ t('SIDEBAR_ITEMS.AVAILABLE_WORKSPACES') }}
      </p>

      <div
        v-if="availableWorkspaces.length"
        class="mb-1 max-h-48 overflow-y-auto"
      >
        <button
          v-for="account in availableWorkspaces"
          :id="`workspace-${account.id}`"
          :key="account.id"
          type="button"
          class="flex w-full cursor-pointer items-center gap-2 rounded-md p-2 text-left transition-colors hover:bg-accent"
          @click="onChangeAccount(account.id)"
        >
          <span
            class="flex size-6 shrink-0 items-center justify-center rounded-full bg-secondary text-xs font-bold text-secondary-foreground"
          >
            {{ accountInitial(account.name) }}
          </span>
          <span
            class="truncate text-sm text-foreground"
            :class="{ 'pl-2 text-muted-foreground': account.isChild }"
          >
            {{ account.name }}
          </span>
        </button>
      </div>
      <p v-else class="px-2 pb-2 text-xs text-muted-foreground">
        {{ t('SIDEBAR_ITEMS.NO_OTHER_WORKSPACES') }}
      </p>

      <div class="my-2 h-px bg-border" />

      <button
        v-if="canCreateWorkspace"
        type="button"
        class="flex w-full cursor-pointer items-center gap-2 rounded-md p-2 text-left text-sm text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
        @click="onAddWorkspace"
      >
        <span class="i-lucide-plus size-4 shrink-0" />
        <span>{{ t('SIDEBAR_ITEMS.ADD_NEW_WORKSPACE') }}</span>
      </button>

      <div v-if="canCreateWorkspace" class="my-1 h-px bg-border" />

      <router-link
        :to="{ name: 'profile_settings_index' }"
        class="flex w-full cursor-pointer items-center gap-2 rounded-md p-2 text-sm text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
        @click="closeMenu"
      >
        <span class="i-lucide-user size-4 shrink-0" />
        <span>{{ t('SIDEBAR_ITEMS.PROFILE_SETTING') }}</span>
      </router-link>
    </div>
  </div>
</template>
