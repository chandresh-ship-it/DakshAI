<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { RelayButton } from 'dashboard/components-next/relay';
import MessageList from './MessageList.vue';
import CaptainAssistant from 'dashboard/api/captain/assistant';

const { assistantId } = defineProps({
  assistantId: {
    type: Number,
    required: true,
  },
});

const { t } = useI18n();
const messages = ref([]);
const newMessage = ref('');
const isLoading = ref(false);

const formatMessagesForApi = () => {
  return messages.value.map(message => {
    const payload = {
      role: message.sender,
      content: message.content,
    };

    if (message.sender === 'assistant' && message.agentName) {
      payload.agent_name = message.agentName;
    }

    return payload;
  });
};

const resetConversation = () => {
  messages.value = [];
  newMessage.value = '';
};

watch(
  () => assistantId,
  (newId, oldId) => {
    if (oldId && newId !== oldId) {
      resetConversation();
    }
  }
);

const sendMessage = async () => {
  if (!newMessage.value.trim() || isLoading.value) return;

  const userMessage = {
    content: newMessage.value,
    sender: 'user',
    timestamp: new Date().toISOString(),
  };
  messages.value.push(userMessage);
  const currentMessage = newMessage.value;
  newMessage.value = '';

  try {
    isLoading.value = true;
    const { data } = await CaptainAssistant.playground({
      assistantId,
      messageContent: currentMessage,
      messageHistory: formatMessagesForApi(),
    });

    messages.value.push({
      content: data.response,
      sender: 'assistant',
      agentName: data.agent_name,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error getting assistant response:', error);
  } finally {
    isLoading.value = false;
  }
};

const handleEnterKey = event => {
  if (event.isComposing) return;
  event.preventDefault();
  sendMessage();
};
</script>

<template>
  <div
    class="flex h-full flex-col rounded-xl border border-n-weak bg-n-solid-2 py-6 text-n-slate-11"
  >
    <div class="mb-6 px-6">
      <div class="mb-1 flex items-center justify-between">
        <h3 class="text-lg font-medium text-n-slate-12">
          {{ t('CAPTAIN.PLAYGROUND.HEADER') }}
        </h3>
        <RelayButton
          variant="ghost"
          size="icon"
          class="size-8 text-n-slate-11"
          :title="t('CAPTAIN.PLAYGROUND.HEADER')"
          @click="resetConversation"
        >
          <span class="i-lucide-rotate-ccw size-4" />
        </RelayButton>
      </div>
      <p class="text-sm text-n-slate-11">
        {{ t('CAPTAIN.PLAYGROUND.DESCRIPTION') }}
      </p>
    </div>

    <MessageList :messages="messages" :is-loading="isLoading" />

    <div
      class="mx-6 flex items-center gap-2 rounded-xl border border-n-weak bg-n-background p-2 shadow-sm"
    >
      <input
        v-model="newMessage"
        class="mb-0 flex-1 border-none bg-transparent px-2 text-sm text-n-slate-12 placeholder:text-n-slate-11 focus:outline-none"
        :placeholder="t('CAPTAIN.PLAYGROUND.MESSAGE_PLACEHOLDER')"
        @keydown.enter.exact="handleEnterKey"
      />
      <RelayButton
        size="icon"
        class="size-9 shrink-0"
        :disabled="!newMessage.trim() || isLoading"
        @click="sendMessage"
      >
        <span
          v-if="isLoading"
          class="i-lucide-loader-circle size-4 animate-spin"
        />
        <span v-else class="i-lucide-send size-4" />
      </RelayButton>
    </div>

    <p class="pt-2 text-center text-xs text-n-slate-11">
      {{ t('CAPTAIN.PLAYGROUND.CREDIT_NOTE') }}
    </p>
  </div>
</template>
