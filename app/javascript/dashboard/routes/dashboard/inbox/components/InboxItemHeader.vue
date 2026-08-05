<script>
import { mapGetters } from 'vuex';
import { useAlert, useTrack } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { getUnixTime } from 'date-fns';
import { CMD_SNOOZE_NOTIFICATION } from 'dashboard/helper/commandbar/events';
import wootConstants from 'dashboard/constants/globals';
import { findSnoozeTime } from 'dashboard/helper/snoozeHelpers';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import PaginationButton from './PaginationButton.vue';
import CustomSnoozeModal from 'dashboard/components/CustomSnoozeModal.vue';
import { emitter } from 'shared/helpers/mitt';
import { RelayButton } from 'dashboard/components-next/relay';

export default {
  components: {
    PaginationButton,
    RelayButton,
    CustomSnoozeModal,
  },
  props: {
    totalLength: {
      type: Number,
      default: 0,
    },
    currentIndex: {
      type: Number,
      default: 0,
    },
    activeNotification: {
      type: Object,
      default: null,
    },
  },
  emits: ['next', 'prev'],
  setup() {
    const { uiSettings, updateUISettings } = useUISettings();
    return { uiSettings, updateUISettings };
  },
  data() {
    return { showCustomSnoozeModal: false };
  },
  computed: {
    ...mapGetters({ meta: 'notifications/getMeta' }),
    isContactSidebarOpen() {
      return this.uiSettings.is_contact_sidebar_open;
    },
  },
  mounted() {
    emitter.on(CMD_SNOOZE_NOTIFICATION, this.onCmdSnoozeNotification);
  },
  unmounted() {
    emitter.off(CMD_SNOOZE_NOTIFICATION, this.onCmdSnoozeNotification);
  },
  methods: {
    openSnoozeNotificationModal() {
      const ninja = document.querySelector('ninja-keys');
      ninja.open({ parent: 'snooze_notification' });
    },
    hideCustomSnoozeModal() {
      this.showCustomSnoozeModal = false;
    },
    async snoozeNotification(snoozedUntil) {
      try {
        await this.$store.dispatch('notifications/snooze', {
          id: this.activeNotification?.id,
          snoozedUntil,
        });

        useAlert(this.$t('INBOX.ALERTS.SNOOZE'));
      } catch (error) {
        // Silently fail without any change in the UI
      }
    },
    onCmdSnoozeNotification(snoozeType) {
      if (snoozeType === wootConstants.SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME) {
        this.showCustomSnoozeModal = true;
      } else if (typeof snoozeType === 'number') {
        this.snoozeNotification(snoozeType);
      } else {
        const snoozedUntil = findSnoozeTime(snoozeType) || null;
        this.snoozeNotification(snoozedUntil);
      }
    },
    scheduleCustomSnooze(customSnoozeTime) {
      this.showCustomSnoozeModal = false;
      if (customSnoozeTime) {
        const snoozedUntil = getUnixTime(customSnoozeTime) || null;
        this.snoozeNotification(snoozedUntil);
      }
    },
    deleteNotification() {
      useTrack(INBOX_EVENTS.DELETE_NOTIFICATION);
      this.$store
        .dispatch('notifications/delete', {
          notification: this.activeNotification,
          unreadCount: this.meta.unreadCount,
          count: this.meta.count,
        })
        .then(() => {
          useAlert(this.$t('INBOX.ALERTS.DELETE'));
        });
      this.$router.replace({ name: 'inbox_view' });
    },
    onClickNext() {
      this.$emit('next');
    },
    onClickPrev() {
      this.$emit('prev');
    },
    onClickGoToInboxList() {
      this.$router.replace({ name: 'inbox_view' });
    },
    toggleContactSidebar() {
      this.updateUISettings({
        is_contact_sidebar_open: !this.isContactSidebarOpen,
        is_copilot_panel_open: false,
      });
    },
  },
};
</script>

<template>
  <div
    class="flex items-center justify-between w-full px-4 h-[60px] border-b border-border bg-card shrink-0"
  >
    <div class="flex items-center">
      <RelayButton
        variant="ghost"
        size="icon"
        class="h-8 w-8 text-muted-foreground hover:text-foreground xl:hidden"
        :aria-label="$t('INBOX.ACTION_HEADER.BACK')"
        @click="onClickGoToInboxList"
      >
        <span class="i-lucide-arrow-left size-4" />
      </RelayButton>
      <!-- Ensure left back arrow shows even on desktop if needed, though mockup has it -->
      <RelayButton
        variant="ghost"
        size="icon"
        class="h-8 w-8 text-muted-foreground hover:text-foreground hidden xl:flex"
        :aria-label="$t('INBOX.ACTION_HEADER.BACK')"
        @click="onClickGoToInboxList"
      >
        <span class="i-lucide-arrow-left size-4" />
      </RelayButton>
    </div>

    <div class="flex items-center gap-3">
      <PaginationButton
        v-if="totalLength > 1"
        :total-length="totalLength"
        :current-index="currentIndex + 1"
        @next="onClickNext"
        @prev="onClickPrev"
      />
      <RelayButton
        variant="ghost"
        size="icon"
        class="h-8 w-8 text-muted-foreground hover:text-foreground"
        :aria-label="$t('INBOX.ACTION_HEADER.SNOOZE')"
        @click="openSnoozeNotificationModal"
      >
        <span class="i-lucide-bell-minus size-4" />
      </RelayButton>
      <RelayButton
        variant="ghost"
        size="icon"
        class="h-8 w-8 text-muted-foreground hover:text-foreground"
        :aria-label="$t('INBOX.ACTION_HEADER.DELETE')"
        @click="deleteNotification"
      >
        <span class="i-lucide-trash-2 size-4" />
      </RelayButton>
      <div class="w-px h-4 bg-border mx-1" />
      <RelayButton
        variant="ghost"
        size="icon"
        class="h-8 w-8 text-muted-foreground hover:text-foreground"
        :class="{ 'bg-accent text-accent-foreground': isContactSidebarOpen }"
        @click="toggleContactSidebar"
      >
        <span class="i-lucide-panel-right size-4" />
      </RelayButton>
    </div>
    <woot-modal
      v-model:show="showCustomSnoozeModal"
      :on-close="hideCustomSnoozeModal"
    >
      <CustomSnoozeModal
        @close="hideCustomSnoozeModal"
        @choose-time="scheduleCustomSnooze"
      />
    </woot-modal>
  </div>
</template>
