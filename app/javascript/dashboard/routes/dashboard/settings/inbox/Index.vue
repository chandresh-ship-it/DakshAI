<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { picoSearch } from '@scmmishra/pico-search';
import Avatar from 'next/avatar/Avatar.vue';
import { useAdmin } from 'dashboard/composables/useAdmin';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsListCard from '../components/SettingsListCard.vue';
import SettingsListRow from '../components/SettingsListRow.vue';
import {
  useMapGetter,
  useStoreGetters,
  useStore,
} from 'dashboard/composables/store';
import ChannelName from './components/ChannelName.vue';
import ChannelIcon from 'next/icon/ChannelIcon.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();
const { isAdmin } = useAdmin();

const showDeletePopup = ref(false);
const selectedInbox = ref({});
const searchQuery = ref('');

const inboxes = useMapGetter('inboxes/getInboxes');

const inboxesList = computed(() => {
  return inboxes.value?.slice().sort((a, b) => a.name.localeCompare(b.name));
});

const filteredInboxesList = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return inboxesList.value;
  return picoSearch(inboxesList.value, query, ['name', 'channel_type']);
});

const uiFlags = computed(() => getters['inboxes/getUIFlags'].value);

const deleteConfirmText = computed(
  () => `${t('INBOX_MGMT.DELETE.CONFIRM.YES')} ${selectedInbox.value.name}`
);

const deleteRejectText = computed(
  () => `${t('INBOX_MGMT.DELETE.CONFIRM.NO')} ${selectedInbox.value.name}`
);

const confirmDeleteMessage = computed(
  () => `${t('INBOX_MGMT.DELETE.CONFIRM.MESSAGE')} ${selectedInbox.value.name}?`
);
const confirmPlaceHolderText = computed(
  () =>
    `${t('INBOX_MGMT.DELETE.CONFIRM.PLACE_HOLDER', {
      inboxName: selectedInbox.value.name,
    })}`
);

const deleteInbox = async ({ id }) => {
  try {
    await store.dispatch('inboxes/delete', id);
    useAlert(t('INBOX_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('INBOX_MGMT.DELETE.API.ERROR_MESSAGE'));
  }
};
const closeDelete = () => {
  showDeletePopup.value = false;
  selectedInbox.value = {};
};

const confirmDeletion = () => {
  deleteInbox(selectedInbox.value);
  closeDelete();
};
const openDelete = inbox => {
  showDeletePopup.value = true;
  selectedInbox.value = inbox;
};
</script>

<template>
  <SettingsLayout
    :no-records-found="!inboxesList.length"
    :no-records-message="$t('INBOX_MGMT.LIST.404')"
    :is-loading="uiFlags.isFetching"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('INBOX_MGMT.HEADER')"
        :description="$t('INBOX_MGMT.DESCRIPTION')"
        :link-text="$t('INBOX_MGMT.LEARN_MORE')"
        :search-placeholder="$t('INBOX_MGMT.SEARCH_PLACEHOLDER')"
        feature-name="inboxes"
      >
        <template v-if="inboxesList?.length" #count>
          <span class="text-sm text-muted-foreground">
            {{ $t('INBOX_MGMT.COUNT', { n: inboxesList.length }) }}
          </span>
        </template>
        <template #actions>
          <router-link v-if="isAdmin" :to="{ name: 'settings_inbox_new' }">
            <RelayButton size="sm">
              {{ $t('SETTINGS.INBOXES.NEW_INBOX') }}
            </RelayButton>
          </router-link>
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <SettingsListCard
        :details-label="$t('INBOX_MGMT.LIST.DETAILS')"
        :actions-label="$t('INBOX_MGMT.LIST.ACTIONS')"
        :show-column-headers="!!filteredInboxesList.length"
      >
        <template v-if="!filteredInboxesList.length && searchQuery" #empty>
          <p class="text-center text-sm text-muted-foreground">
            {{ $t('INBOX_MGMT.NO_RESULTS') }}
          </p>
        </template>
        <SettingsListRow v-for="inbox in filteredInboxesList" :key="inbox.id">
          <template #leading>
            <div
              v-if="inbox.avatar_url"
              class="grid size-10 place-items-center rounded-xl border border-border/60 bg-background shadow-xs"
            >
              <Avatar
                :src="inbox.avatar_url"
                :name="inbox.name"
                :size="24"
                rounded-full
              />
            </div>
            <div
              v-else
              class="grid size-10 place-items-center rounded-xl border border-border/60 bg-background shadow-xs"
            >
              <ChannelIcon
                class="size-4 text-muted-foreground"
                :inbox="inbox"
              />
            </div>
          </template>
          <span class="text-sm font-medium capitalize text-foreground">
            {{ inbox.name }}
          </span>
          <ChannelName
            :channel-type="inbox.channel_type"
            :medium="inbox.medium"
            :voice-enabled="inbox.voice_enabled"
            class="mt-0.5 text-xs text-muted-foreground"
          />
          <template #actions>
            <router-link
              :to="{
                name: 'settings_inbox_show',
                params: { inboxId: inbox.id },
              }"
            >
              <RelayButton
                v-if="isAdmin"
                v-tooltip.top="$t('INBOX_MGMT.SETTINGS')"
                variant="ghost"
                size="icon"
                class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-border hover:bg-background hover:text-foreground"
              >
                <Icon icon="i-lucide-sliders-horizontal" class="size-3.5" />
              </RelayButton>
            </router-link>
            <RelayButton
              v-if="isAdmin"
              v-tooltip.top="$t('INBOX_MGMT.DELETE.BUTTON_TEXT')"
              variant="ghost"
              size="icon"
              class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-red-100 hover:bg-red-50 hover:text-red-600"
              @click="openDelete(inbox)"
            >
              <Icon icon="i-lucide-trash-2" class="size-3.5" />
            </RelayButton>
          </template>
        </SettingsListRow>
      </SettingsListCard>
    </template>

    <woot-confirm-delete-modal
      v-if="showDeletePopup"
      v-model:show="showDeletePopup"
      :title="$t('INBOX_MGMT.DELETE.CONFIRM.TITLE')"
      :message="confirmDeleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
      :confirm-value="selectedInbox.name"
      :confirm-place-holder-text="confirmPlaceHolderText"
      @on-confirm="confirmDeletion"
      @on-close="closeDelete"
    />
  </SettingsLayout>
</template>
