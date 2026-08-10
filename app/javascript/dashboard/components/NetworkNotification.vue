<script setup>
import { ref, computed, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useEmitter } from 'dashboard/composables/emitter';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import {
  isAConversationRoute,
  isAInboxViewRoute,
  isNotificationRoute,
} from 'dashboard/helper/routeHelpers';
import { useEventListener } from '@vueuse/core';

const { t } = useI18n();
const route = useRoute();

const RECONNECTED_BANNER_TIMEOUT = 2000;

const showNotification = ref(!navigator.onLine);
const isDisconnected = ref(false);
const isReconnecting = ref(false);
const isReconnected = ref(false);
let reconnectTimeout = null;

const bannerText = computed(() => {
  if (isReconnecting.value) return t('NETWORK.NOTIFICATION.RECONNECTING');
  if (isReconnected.value) return t('NETWORK.NOTIFICATION.RECONNECT_SUCCESS');
  return t('NETWORK.NOTIFICATION.OFFLINE');
});

const canRefresh = computed(
  () => !isReconnecting.value && !isReconnected.value
);

const refreshPage = () => {
  window.location.reload();
};

const closeNotification = () => {
  showNotification.value = false;
  isReconnected.value = false;
  clearTimeout(reconnectTimeout);
};

const isInAnyOfTheRoutes = routeName => {
  return (
    isAConversationRoute(routeName, true) ||
    isAInboxViewRoute(routeName, true) ||
    isNotificationRoute(routeName, true)
  );
};

const updateWebsocketStatus = () => {
  isDisconnected.value = true;
  showNotification.value = true;
};

const handleReconnectionCompleted = () => {
  isDisconnected.value = false;
  isReconnecting.value = false;
  isReconnected.value = true;
  showNotification.value = true;
  reconnectTimeout = setTimeout(closeNotification, RECONNECTED_BANNER_TIMEOUT);
};

const handleReconnecting = () => {
  if (isInAnyOfTheRoutes(route.name)) {
    isReconnecting.value = true;
    isReconnected.value = false;
    showNotification.value = true;
  } else {
    handleReconnectionCompleted();
  }
};

const updateOnlineStatus = event => {
  if (event.type === 'offline') {
    showNotification.value = true;
  } else if (event.type === 'online' && !isDisconnected.value) {
    handleReconnectionCompleted();
  }
};

useEventListener('online', updateOnlineStatus);
useEventListener('offline', updateOnlineStatus);
useEmitter(BUS_EVENTS.WEBSOCKET_DISCONNECT, updateWebsocketStatus);
useEmitter(
  BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED,
  handleReconnectionCompleted
);
useEmitter(BUS_EVENTS.WEBSOCKET_RECONNECT, handleReconnecting);

onBeforeUnmount(() => {
  clearTimeout(reconnectTimeout);
});
</script>

<template>
  <transition
    enter-active-class="transition duration-300 ease-out"
    enter-from-class="transform -translate-y-2 opacity-0"
    enter-to-class="transform translate-y-0 opacity-100"
    leave-active-class="transition duration-200 ease-in"
    leave-from-class="transform translate-y-0 opacity-100"
    leave-to-class="transform -translate-y-2 opacity-0"
  >
    <div
      v-show="showNotification"
      class="fixed top-4 left-4 z-50 flex items-center gap-2.5 rounded-xl border px-3 py-2 text-xs font-medium shadow-md backdrop-blur-sm transition-all"
      :class="[
        isReconnected
          ? 'border-emerald-500/30 bg-emerald-500/10 text-emerald-700 dark:bg-emerald-500/15 dark:text-emerald-300'
          : 'border-amber-500/30 bg-amber-500/10 text-amber-700 dark:bg-amber-500/15 dark:text-amber-300',
      ]"
    >
      <span
        v-if="isReconnecting"
        class="i-lucide-loader-2 size-4 shrink-0 animate-spin text-amber-500"
      />
      <span
        v-else-if="isReconnected"
        class="i-lucide-wifi size-4 shrink-0 text-emerald-500"
      />
      <span v-else class="i-lucide-wifi-off size-4 shrink-0 text-amber-500" />

      <span class="font-medium tracking-tight">
        {{ bannerText }}
      </span>

      <div class="ml-1 flex shrink-0 items-center gap-1">
        <button
          v-if="canRefresh"
          type="button"
          class="flex size-6 items-center justify-center rounded-md transition-colors hover:bg-black/5 dark:hover:bg-white/10"
          :title="$t('NETWORK.BUTTON.REFRESH')"
          @click="refreshPage"
        >
          <span class="i-lucide-refresh-cw size-3.5" />
        </button>

        <button
          type="button"
          class="flex size-6 items-center justify-center rounded-md transition-colors hover:bg-black/5 dark:hover:bg-white/10"
          @click="closeNotification"
        >
          <span class="i-lucide-x size-3.5" />
        </button>
      </div>
    </div>
  </transition>
</template>
