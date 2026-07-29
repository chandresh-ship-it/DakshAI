<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';

import { RelayButton } from 'dashboard/components-next/relay';

const emit = defineEmits(['close', 'createAssistant']);

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();

const assistants = useMapGetter('captainAssistants/getRecords');

const currentAssistantId = computed(() => route.params.assistantId);

const isAssistantActive = assistant => {
  return assistant.id === Number(currentAssistantId.value);
};

const fetchDataForRoute = async (routeName, assistantId) => {
  const dataFetchMap = {
    captain_assistants_responses_index: async () => {
      await store.dispatch('captainResponses/get', { assistantId });
      await store.dispatch('captainResponses/fetchPendingCount', assistantId);
    },
    captain_assistants_responses_pending: async () => {
      await store.dispatch('captainResponses/get', {
        assistantId,
        status: 'pending',
      });
    },
    captain_assistants_documents_index: async () => {
      await store.dispatch('captainDocuments/get', { assistantId });
    },
    captain_assistants_scenarios_index: async () => {
      await store.dispatch('captainScenarios/get', { assistantId });
    },
    captain_assistants_playground_index: () => {
      // Playground doesn't need pre-fetching, it loads on interaction
    },
    captain_assistants_inboxes_index: async () => {
      await store.dispatch('captainInboxes/get', { assistantId });
    },
    captain_tools_index: async () => {
      await store.dispatch('captainCustomTools/get', { page: 1 });
    },
    captain_assistants_settings_index: async () => {
      await store.dispatch('captainAssistants/show', assistantId);
    },
  };

  const fetchFn = dataFetchMap[routeName];
  if (fetchFn) {
    await fetchFn();
  }
};

const handleAssistantChange = async assistant => {
  if (isAssistantActive(assistant)) return;

  const currentRouteName = route.name;
  const targetRouteName =
    currentRouteName || 'captain_assistants_responses_index';

  await fetchDataForRoute(targetRouteName, assistant.id);

  await router.push({
    name: targetRouteName,
    params: {
      accountId: route.params.accountId,
      assistantId: assistant.id,
    },
  });

  emit('close');
};

const openCreateAssistantDialog = () => {
  emit('createAssistant');
  emit('close');
};
</script>

<template>
  <div
    class="absolute z-50 flex w-[17.5rem] flex-col gap-1 rounded-xl bg-n-alpha-3 pt-2 pb-2 shadow-md outline outline-1 outline-n-container backdrop-blur-[100px]"
  >
    <div
      class="mb-1 flex items-start justify-between gap-2 border-b border-n-weak px-3 pb-2"
    >
      <div class="flex min-w-0 flex-1 flex-col gap-0.5">
        <h2 class="text-sm font-semibold text-n-slate-12">
          {{ t('CAPTAIN.ASSISTANT_SWITCHER.ASSISTANTS') }}
        </h2>
        <p class="text-xs leading-snug text-n-slate-11">
          {{ t('CAPTAIN.ASSISTANT_SWITCHER.SWITCH_ASSISTANT') }}
        </p>
      </div>
      <RelayButton
        variant="outline"
        size="sm"
        class="h-7 shrink-0 rounded-full px-3 text-xs"
        @click="openCreateAssistantDialog"
      >
        <span class="i-lucide-plus size-3" />
        {{ t('CAPTAIN.ASSISTANT_SWITCHER.NEW_ASSISTANT') }}
      </RelayButton>
    </div>
    <div v-if="assistants.length > 0" class="flex flex-col gap-0.5 px-1.5">
      <RelayButton
        v-for="assistant in assistants"
        :key="assistant.id"
        variant="ghost"
        size="sm"
        class="h-9 w-full justify-start gap-2 !px-2 !py-2 hover:bg-n-alpha-2"
        @click="handleAssistantChange(assistant)"
      >
        <span
          class="i-lucide-brain-circuit size-4 shrink-0"
          :class="
            isAssistantActive(assistant) ? 'text-n-brand' : 'text-n-slate-11'
          "
        />
        <span
          class="min-w-0 flex-1 truncate text-start text-sm font-medium text-n-slate-12"
        >
          {{ assistant.name || '' }}
        </span>
        <span
          v-if="isAssistantActive(assistant)"
          class="i-lucide-check size-4 shrink-0 text-n-brand"
        />
      </RelayButton>
    </div>
    <div v-else class="flex flex-col items-center gap-2 px-4 py-3">
      <p class="text-sm text-n-slate-11">
        {{ t('CAPTAIN.ASSISTANT_SWITCHER.EMPTY_LIST') }}
      </p>
    </div>
  </div>
</template>
