<script setup>
import { computed } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import ButtonNext from 'next/button/Button.vue';
import Icon from 'next/icon/Icon.vue';

import {
  DropdownContainer,
  DropdownBody,
  DropdownSection,
  DropdownItem,
} from 'next/dropdown-menu/base';

defineProps({
  isCollapsed: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['showCreateAccountModal']);

const { t } = useI18n();
const { accountId, currentAccount } = useAccount();
const currentUser = useMapGetter('getCurrentUser');
const globalConfig = useMapGetter('globalConfig/get');

const userAccounts = useMapGetter('getUserAccounts');

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

const showAccountSwitcher = computed(
  () =>
    (userAccounts.value.length > 1 ||
      (globalConfig.value.createNewAccountFromDashboard &&
        isAdmin.value &&
        !isSubAccount.value)) &&
    currentAccount.value.name
);

const sortedCurrentUserAccounts = computed(() => {
  const accounts = currentUser.value.accounts || [];
  const parents = accounts
    .filter(a => !a.parent_id)
    .sort((a, b) => a.name.localeCompare(b.name));
  const result = [];

  parents.forEach(parent => {
    result.push(parent);
    const children = accounts
      .filter(a => a.parent_id === parent.id)
      .sort((a, b) => a.name.localeCompare(b.name));
    children.forEach(child => {
      result.push({ ...child, isChild: true });
    });
  });

  const childIdsInResult = result.map(a => a.id);
  const orphans = accounts
    .filter(a => a.parent_id && !childIdsInResult.includes(a.id))
    .sort((a, b) => a.name.localeCompare(b.name));
  result.push(...orphans);

  return result;
});

const onChangeAccount = newId => {
  const accountUrl = `/app/accounts/${newId}/dashboard`;
  window.location.href = accountUrl;
};

const emitNewAccount = () => {
  emit('showCreateAccountModal');
};
</script>

<template>
  <DropdownContainer>
    <template #trigger="{ toggle, isOpen }">
      <!-- Collapsed view: Brand initial trigger -->
      <button
        v-if="isCollapsed"
        class="flex size-8 shrink-0 cursor-pointer items-center justify-center rounded-lg bg-sidebar-primary text-sm font-bold text-sidebar-primary-foreground hover:opacity-90"
        :class="{ 'ring-2 ring-sidebar-primary/40': isOpen }"
        :title="currentAccount.name"
        @click="toggle"
      >
        {{ (currentAccount.name || 'N').charAt(0).toUpperCase() }}
      </button>
      <!-- Expanded view: Account name trigger -->
      <button
        v-else
        id="sidebar-account-switcher"
        :data-account-id="accountId"
        aria-haspopup="listbox"
        aria-controls="account-options"
        class="flex items-center gap-2 justify-between w-full rounded-md px-2"
        :class="[
          isOpen && 'bg-sidebar-accent',
          showAccountSwitcher
            ? 'hover:bg-sidebar-accent cursor-pointer'
            : 'cursor-default',
        ]"
        @click="() => showAccountSwitcher && toggle()"
      >
        <span
          class="truncate text-sm font-semibold leading-tight text-sidebar-foreground"
          aria-live="polite"
        >
          {{ currentAccount.name }}
        </span>

        <span
          v-if="showAccountSwitcher"
          aria-hidden="true"
          class="i-lucide-chevron-down size-4 text-muted-foreground flex-shrink-0"
        />
      </button>
    </template>
    <DropdownBody
      v-if="showAccountSwitcher || isCollapsed"
      class="min-w-80 z-50"
    >
      <DropdownSection :title="t('SIDEBAR_ITEMS.SWITCH_ACCOUNT')">
        <DropdownItem
          v-for="account in sortedCurrentUserAccounts"
          :id="`account-${account.id}`"
          :key="account.id"
          class="cursor-pointer"
          @click="onChangeAccount(account.id)"
        >
          <template #label>
            <div
              :for="account.name"
              class="text-left rtl:text-right flex gap-2 items-center"
              :class="{ 'pl-5 text-muted-foreground': account.isChild }"
            >
              <span
                v-if="account.isChild"
                class="text-muted-foreground mr-1 before:content-['\u21b3']"
              />
              <span
                class="text-foreground max-w-36 truncate min-w-0"
                :title="account.name"
                :class="{ '!text-muted-foreground': account.isChild }"
              >
                {{ account.name }}
              </span>
              <div class="flex-shrink-0 w-px h-3 bg-border" />
              <span
                class="text-muted-foreground max-w-24 truncate capitalize"
                :title="account.name"
              >
                {{
                  account.custom_role_id
                    ? account.custom_role.name
                    : account.role
                }}
              </span>
            </div>
            <Icon
              v-show="account.id === accountId"
              icon="i-lucide-check"
              class="text-success size-5"
            />
          </template>
        </DropdownItem>
      </DropdownSection>
      <DropdownItem
        v-if="
          globalConfig.createNewAccountFromDashboard && isAdmin && !isSubAccount
        "
      >
        <ButtonNext
          color="slate"
          variant="faded"
          class="w-full"
          size="sm"
          @click="emitNewAccount"
        >
          {{ t('CREATE_ACCOUNT.NEW_ACCOUNT') }}
        </ButtonNext>
      </DropdownItem>
    </DropdownBody>
  </DropdownContainer>
</template>
