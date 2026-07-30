<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onMounted, ref } from 'vue';
import Avatar from 'next/avatar/Avatar.vue';
import { useI18n } from 'vue-i18n';
import { picoSearch } from '@scmmishra/pico-search';
import {
  useStoreGetters,
  useStore,
  useMapGetter,
} from 'dashboard/composables/store';

import AddAgent from './AddAgent.vue';
import EditAgent from './EditAgent.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import SettingsListCard from '../components/SettingsListCard.vue';
import SettingsListRow from '../components/SettingsListRow.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const loading = ref({});
const showAddPopup = ref(false);
const showDeletePopup = ref(false);
const showEditPopup = ref(false);
const agentAPI = ref({ message: '' });
const currentAgent = ref({});
const searchQuery = ref('');

const deleteConfirmText = computed(
  () => `${t('AGENT_MGMT.DELETE.CONFIRM.YES')} ${currentAgent.value.name}`
);
const deleteRejectText = computed(() => {
  return `${t('AGENT_MGMT.DELETE.CONFIRM.NO')} ${currentAgent.value.name}`;
});
const deleteMessage = computed(() => {
  return ` ${currentAgent.value.name}?`;
});

const agentList = computed(() => getters['agents/getAgents'].value);

const filteredAgentList = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return agentList.value;
  return picoSearch(agentList.value, query, ['name', 'email']);
});

const uiFlags = computed(() => getters['agents/getUIFlags'].value);
const currentUserId = computed(() => getters.getCurrentUserID.value);
const customRoles = useMapGetter('customRole/getCustomRoles');

onMounted(() => {
  store.dispatch('agents/get');
  store.dispatch('customRole/getCustomRole');
});

const findCustomRole = agent =>
  customRoles.value.find(role => role.id === agent.custom_role_id);

const getAgentRoleName = agent => {
  if (!agent.custom_role_id) {
    return t(`AGENT_MGMT.AGENT_TYPES.${agent.role.toUpperCase()}`);
  }
  const customRole = findCustomRole(agent);
  return customRole ? customRole.name : '';
};

const getAgentRolePermissions = agent => {
  if (!agent.custom_role_id) {
    return [];
  }
  const customRole = findCustomRole(agent);
  return customRole?.permissions || [];
};

const verifiedAdministrators = computed(() => {
  return agentList.value.filter(
    agent => agent.role === 'administrator' && agent.confirmed
  );
});

const showEditAction = agent => {
  return currentUserId.value !== agent.id;
};

const showDeleteAction = agent => {
  if (currentUserId.value === agent.id) {
    return false;
  }

  if (!agent.confirmed) {
    return true;
  }

  if (agent.role === 'administrator') {
    return verifiedAdministrators.value.length !== 1;
  }
  return true;
};

const showAlertMessage = message => {
  loading.value[currentAgent.value.id] = false;
  currentAgent.value = {};
  agentAPI.value.message = message;
  useAlert(message);
};

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = agent => {
  showEditPopup.value = true;
  currentAgent.value = agent;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
};

const openDeletePopup = agent => {
  showDeletePopup.value = true;
  currentAgent.value = agent;
};
const closeDeletePopup = () => {
  showDeletePopup.value = false;
};

const deleteAgent = async id => {
  try {
    await store.dispatch('agents/delete', id);
    showAlertMessage(t('AGENT_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    showAlertMessage(t('AGENT_MGMT.DELETE.API.ERROR_MESSAGE'));
  }
};
const confirmDeletion = () => {
  loading.value[currentAgent.value.id] = true;
  closeDeletePopup();
  deleteAgent(currentAgent.value.id);
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('AGENT_MGMT.LOADING')"
    :no-records-found="!agentList.length"
    :no-records-message="$t('AGENT_MGMT.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('AGENT_MGMT.HEADER')"
        :description="$t('AGENT_MGMT.DESCRIPTION')"
        :link-text="$t('AGENT_MGMT.LEARN_MORE')"
        :search-placeholder="$t('AGENT_MGMT.SEARCH_PLACEHOLDER')"
        feature-name="agents"
      >
        <template v-if="agentList?.length" #count>
          <span class="text-sm text-muted-foreground">
            {{ $t('AGENT_MGMT.COUNT', { n: agentList.length }) }}
          </span>
        </template>
        <template #actions>
          <RelayButton size="sm" @click="openAddPopup">
            {{ $t('AGENT_MGMT.HEADER_BTN_TXT') }}
          </RelayButton>
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <SettingsListCard
        :details-label="$t('AGENT_MGMT.LIST.DETAILS')"
        :actions-label="$t('AGENT_MGMT.LIST.ACTIONS')"
        :show-column-headers="!!filteredAgentList.length"
      >
        <template v-if="!filteredAgentList.length && searchQuery" #empty>
          <p class="text-center text-sm text-muted-foreground">
            {{ $t('AGENT_MGMT.NO_RESULTS') }}
          </p>
        </template>
        <SettingsListRow
          v-for="(agent, index) in filteredAgentList"
          :key="agent.email"
        >
          <template #leading>
            <Avatar
              :src="agent.thumbnail"
              :name="agent.name"
              :status="agent.availability_status"
              :size="40"
              hide-offline-status
            />
          </template>
          <span class="text-sm font-medium capitalize text-foreground">
            {{ agent.name }}
          </span>
          <div
            class="mt-1 flex flex-wrap items-center gap-3.5 text-[13px] text-muted-foreground"
          >
            <span>{{ agent.email }}</span>
            <div class="size-1 rounded-full bg-muted-foreground/40" />
            <span
              class="relative"
              :class="{
                'group/role cursor-pointer hover:text-foreground':
                  agent.custom_role_id,
              }"
            >
              {{ getAgentRoleName(agent) }}
              <div
                class="absolute top-14 z-10 hidden w-[300px] rounded-xl border border-border bg-card p-4 shadow-lg backdrop-blur-[100px] ltr:left-0 rtl:right-0 md:top-12"
                :class="{ 'group-hover/role:block': agent.custom_role_id }"
              >
                <div class="flex flex-col gap-1">
                  <span class="text-sm font-medium text-foreground">
                    {{ $t('AGENT_MGMT.LIST.AVAILABLE_CUSTOM_ROLE') }}
                  </span>
                  <ul class="mb-0 list-disc ltr:pl-4 rtl:pr-4">
                    <li
                      v-for="permission in getAgentRolePermissions(agent)"
                      :key="permission"
                      class="text-[13px] text-muted-foreground"
                    >
                      {{
                        $t(
                          `CUSTOM_ROLE.PERMISSIONS.${permission.toUpperCase()}`
                        )
                      }}
                    </li>
                  </ul>
                </div>
              </div>
            </span>
            <div class="size-1 rounded-full bg-muted-foreground/40" />
            <span v-if="agent.confirmed">
              {{ $t('AGENT_MGMT.LIST.VERIFIED') }}
            </span>
            <span v-else>
              {{ $t('AGENT_MGMT.LIST.VERIFICATION_PENDING') }}
            </span>
          </div>
          <template #actions>
            <RelayButton
              v-if="showEditAction(agent)"
              v-tooltip.top="$t('AGENT_MGMT.EDIT.BUTTON_TEXT')"
              variant="ghost"
              size="icon"
              class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-border hover:bg-background hover:text-foreground"
              @click="openEditPopup(agent)"
            >
              <Icon icon="i-lucide-pencil" class="size-3.5" />
            </RelayButton>
            <RelayButton
              v-if="showDeleteAction(agent)"
              v-tooltip.top="$t('AGENT_MGMT.DELETE.BUTTON_TEXT')"
              variant="ghost"
              size="icon"
              class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-red-100 hover:bg-red-50 hover:text-red-600"
              :disabled="loading[agent.id]"
              @click="openDeletePopup(agent, index)"
            >
              <Icon icon="i-lucide-trash-2" class="size-3.5" />
            </RelayButton>
          </template>
        </SettingsListRow>
      </SettingsListCard>
    </template>

    <woot-modal v-model:show="showAddPopup" :on-close="hideAddPopup">
      <AddAgent @close="hideAddPopup" />
    </woot-modal>

    <woot-modal v-model:show="showEditPopup" :on-close="hideEditPopup">
      <EditAgent
        v-if="showEditPopup"
        :id="currentAgent.id"
        :name="currentAgent.name"
        :provider="currentAgent.provider"
        :type="currentAgent.role"
        :email="currentAgent.email"
        :availability="currentAgent.availability_status"
        :custom-role-id="currentAgent.custom_role_id"
        @close="hideEditPopup"
      />
    </woot-modal>

    <woot-delete-modal
      v-model:show="showDeletePopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('AGENT_MGMT.DELETE.CONFIRM.TITLE')"
      :message="$t('AGENT_MGMT.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />
  </SettingsLayout>
</template>
