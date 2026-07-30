<script setup>
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import { computed, ref } from 'vue';
import { picoSearch } from '@scmmishra/pico-search';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const store = useStore();
const { t } = useI18n();
const getters = useStoreGetters();
const { isAdmin } = useAdmin();

const loading = ref({});
const searchQuery = ref('');

const teamsList = useMapGetter('teams/getTeams');

const filteredTeamsList = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return teamsList.value;
  return picoSearch(teamsList.value, query, ['name', 'description']);
});

const uiFlags = computed(() => getters['teams/getUIFlags'].value);

const deleteTeam = async ({ id }) => {
  try {
    loading.value[id] = true;
    await store.dispatch('teams/delete', id);
    useAlert(t('TEAMS_SETTINGS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('TEAMS_SETTINGS.DELETE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[id] = false;
  }
};

const showDeletePopup = ref(false);
const selectedTeam = ref({});

const openDelete = team => {
  showDeletePopup.value = true;
  selectedTeam.value = team;
};

const closeDelete = () => {
  showDeletePopup.value = false;
  selectedTeam.value = {};
};

const confirmDeletion = () => {
  deleteTeam(selectedTeam.value);
  closeDelete();
};

const deleteConfirmText = computed(
  () => `${t('TEAMS_SETTINGS.DELETE.CONFIRM.YES')} ${selectedTeam.value.name}`
);

const deleteRejectText = computed(() => t('TEAMS_SETTINGS.DELETE.CONFIRM.NO'));

const confirmDeleteTitle = computed(() =>
  t('TEAMS_SETTINGS.DELETE.CONFIRM.TITLE', {
    teamName: selectedTeam.value.name,
  })
);

const confirmPlaceHolderText = computed(() =>
  t('TEAMS_SETTINGS.DELETE.CONFIRM.PLACE_HOLDER', {
    teamName: selectedTeam.value.name,
  })
);
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('TEAMS_SETTINGS.LOADING')"
    :no-records-found="!teamsList.length"
    :no-records-message="$t('TEAMS_SETTINGS.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('TEAMS_SETTINGS.HEADER')"
        :description="$t('TEAMS_SETTINGS.DESCRIPTION')"
        :link-text="$t('TEAMS_SETTINGS.LEARN_MORE')"
        :search-placeholder="$t('TEAMS_SETTINGS.SEARCH_PLACEHOLDER')"
        feature-name="team_management"
      >
        <template v-if="teamsList?.length" #count>
          <span class="text-sm text-muted-foreground">
            {{ $t('TEAMS_SETTINGS.COUNT', { n: teamsList.length }) }}
          </span>
        </template>
        <template #actions>
          <router-link v-if="isAdmin" :to="{ name: 'settings_teams_new' }">
            <RelayButton size="sm">
              {{ $t('TEAMS_SETTINGS.NEW_TEAM') }}
            </RelayButton>
          </router-link>
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div class="grid grid-cols-1 gap-5 md:grid-cols-2 lg:grid-cols-3">
        <template v-if="!filteredTeamsList.length && searchQuery">
          <p
            class="col-span-full py-20 text-center text-sm text-muted-foreground"
          >
            {{ $t('TEAMS_SETTINGS.NO_RESULTS') }}
          </p>
        </template>
        <div
          v-for="team in filteredTeamsList"
          :key="team.id"
          class="group flex h-full flex-col gap-5 rounded-xl border border-border/80 bg-card p-5 shadow-xs transition-colors hover:border-border"
        >
          <div class="flex w-full flex-col items-start gap-4">
            <div
              class="flex size-12 shrink-0 items-center justify-center rounded-xl bg-primary/10"
            >
              <Icon icon="i-lucide-users-round" class="size-6 text-primary" />
            </div>
            <div>
              <h3 class="text-base font-semibold text-foreground">
                {{ team.name }}
              </h3>
              <p
                class="mt-1 pr-4 text-[13px] leading-relaxed text-muted-foreground"
              >
                {{ team.description }}
              </p>
            </div>
          </div>
          <div
            class="mt-auto flex items-center justify-between gap-3 border-t border-border/40 pt-4"
          >
            <router-link
              :to="{
                name: 'settings_teams_edit',
                params: { teamId: team.id },
              }"
            >
              <RelayButton
                v-if="isAdmin"
                variant="outline"
                size="sm"
                class="h-9 border-border/80 bg-background px-4 text-[13px] font-medium shadow-xs"
              >
                {{ $t('TEAMS_SETTINGS.LIST.VIEW_TEAM') }}
              </RelayButton>
            </router-link>
            <RelayButton
              v-if="isAdmin"
              v-tooltip.top="$t('TEAMS_SETTINGS.DELETE.BUTTON_TEXT')"
              variant="outline"
              size="icon"
              class="size-9 border-border/80 bg-background text-muted-foreground shadow-xs hover:bg-muted hover:text-foreground"
              :disabled="loading[team.id]"
              @click="openDelete(team)"
            >
              <Icon icon="i-lucide-trash-2" class="size-4" />
            </RelayButton>
          </div>
        </div>
      </div>
    </template>
    <woot-confirm-delete-modal
      v-if="showDeletePopup"
      v-model:show="showDeletePopup"
      :title="confirmDeleteTitle"
      :message="$t('TEAMS_SETTINGS.DELETE.CONFIRM.MESSAGE')"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
      :confirm-value="selectedTeam.name"
      :confirm-place-holder-text="confirmPlaceHolderText"
      @on-confirm="confirmDeletion"
      @on-close="closeDelete"
    />
  </SettingsLayout>
</template>
