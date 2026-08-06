<script>
import { ref } from 'vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import FileUpload from 'vue-upload-component';
import * as ActiveStorage from 'activestorage';
import inboxMixin from 'shared/mixins/inboxMixin';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { getAllowedFileTypesByChannel } from '@chatwoot/utils';
import VideoCallButton from '../VideoCallButton.vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { mapGetters } from 'vuex';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { useCaptain } from 'dashboard/composables/useCaptain';

export default {
  name: 'ReplyBottomPanel',
  components: { NextButton, FileUpload, VideoCallButton },
  mixins: [inboxMixin],
  props: {
    isNote: {
      type: Boolean,
      default: false,
    },
    onSend: {
      type: Function,
      default: () => {},
    },
    sendButtonText: {
      type: String,
      default: '',
    },
    recordingAudioDurationText: {
      type: String,
      default: '00:00',
    },
    // inbox prop is used in /mixins/inboxMixin,
    // remove this props when refactoring to composable if not needed
    // eslint-disable-next-line vue/no-unused-properties
    inbox: {
      type: Object,
      default: () => ({}),
    },
    showFileUpload: {
      type: Boolean,
      default: false,
    },
    showAudioRecorder: {
      type: Boolean,
      default: false,
    },
    onFileUpload: {
      type: Function,
      default: () => {},
    },
    toggleEmojiPicker: {
      type: Function,
      default: () => {},
    },
    toggleAudioRecorder: {
      type: Function,
      default: () => {},
    },
    toggleAudioRecorderPlayPause: {
      type: Function,
      default: () => {},
    },
    isRecordingAudio: {
      type: Boolean,
      default: false,
    },
    recordingAudioState: {
      type: String,
      default: '',
    },
    isSendDisabled: {
      type: Boolean,
      default: false,
    },
    isOnPrivateNote: {
      type: Boolean,
      default: false,
    },
    enableMultipleFileUpload: {
      type: Boolean,
      default: true,
    },
    enableWhatsAppTemplates: {
      type: Boolean,
      default: false,
    },
    enableContentTemplates: {
      type: Boolean,
      default: false,
    },
    conversationId: {
      type: Number,
      required: true,
    },
    // eslint-disable-next-line vue/no-unused-properties
    message: {
      type: String,
      default: '',
    },
    newConversationModalActive: {
      type: Boolean,
      default: false,
    },
    portalSlug: {
      type: String,
      required: true,
    },
    conversationType: {
      type: String,
      default: '',
    },
    showQuotedReplyToggle: {
      type: Boolean,
      default: false,
    },
    quotedReplyEnabled: {
      type: Boolean,
      default: false,
    },
    isEditorDisabled: {
      type: Boolean,
      default: false,
    },
  },
  emits: [
    'toggleInsertArticle',
    'selectWhatsappTemplate',
    'selectContentTemplate',
    'toggleQuotedReply',
    'toggleCopilot',
  ],
  setup(props) {
    const { setSignatureFlagForInbox, fetchSignatureFlagFromUISettings } =
      useUISettings();

    const uploadRef = ref(false);

    const keyboardEvents = {
      '$mod+Alt+KeyA': {
        action: () => {
          // Skip if editor is disabled (e.g., WhatsApp 24-hour window expired)
          if (props.isEditorDisabled) return;

          // TODO: This is really hacky, we need to replace the file picker component with
          // a custom one, where the logic and the component markup is isolated.
          // Once we have the custom component, we can remove the hacky logic below.

          const uploadTriggerButton = document.querySelector(
            '#conversationAttachment'
          );
          if (uploadTriggerButton) uploadTriggerButton.click();
        },
        allowOnFocusedInput: true,
      },
    };

    useKeyboardEvents(keyboardEvents);

    const { captainTasksEnabled } = useCaptain();

    const handleEmojiPickerClick = (e) => {
      if (e) {
        e.preventDefault();
        e.stopPropagation();
      }
      if (props.toggleEmojiPicker) {
        props.toggleEmojiPicker();
      }
    };

    return {
      setSignatureFlagForInbox,
      fetchSignatureFlagFromUISettings,
      uploadRef,
      captainTasksEnabled,
      handleEmojiPickerClick,
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
      uiFlags: 'integrations/getUIFlags',
    }),
    wrapClass() {
      return {
        'is-note-mode': this.isNote,
      };
    },
    showAttachButton() {
      if (this.isEditorDisabled) return false;
      return this.showFileUpload || this.isNote;
    },
    showAudioRecorderButton() {
      if (this.isEditorDisabled) return false;
      if (this.isALineChannel || this.isATiktokChannel) {
        return false;
      }
      // Disable audio recorder for safari browser as recording is not supported
      // const isSafari = /^((?!chrome|android|crios|fxios).)*safari/i.test(
      //   navigator.userAgent
      // );

      return (
        this.isFeatureEnabledonAccount(
          this.accountId,
          FEATURE_FLAGS.VOICE_RECORDER
        ) && this.showAudioRecorder
        // !isSafari
      );
    },
    showAudioPlayStopButton() {
      if (this.isEditorDisabled) return false;
      return this.showAudioRecorder && this.isRecordingAudio;
    },
    isInstagramDM() {
      return this.conversationType === 'instagram_direct_message';
    },
    allowedFileTypes() {
      if (this.isOnPrivateNote) {
        return getAllowedFileTypesByChannel();
      }

      let channelType = this.channelType || this.inbox?.channel_type;
      if (this.isAnInstagramChannel || this.isInstagramDM) {
        channelType = INBOX_TYPES.INSTAGRAM;
      }

      return getAllowedFileTypesByChannel({
        channelType,
        medium: this.inbox?.medium,
      });
    },
    enableDragAndDrop() {
      return !this.newConversationModalActive;
    },
    audioRecorderPlayStopIcon() {
      switch (this.recordingAudioState) {
        // playing paused recording stopped inactive destroyed
        case 'playing':
          return 'i-ph-pause';
        case 'paused':
          return 'i-ph-play';
        case 'stopped':
          return 'i-ph-play';
        default:
          return 'i-ph-stop';
      }
    },
    showMessageSignatureButton() {
      if (this.isEditorDisabled) return false;
      return !this.isOnPrivateNote;
    },
    sendWithSignature() {
      // channelType is sourced from inboxMixin
      return this.fetchSignatureFlagFromUISettings(this.channelType);
    },
    signatureToggleTooltip() {
      return this.sendWithSignature
        ? this.$t('CONVERSATION.FOOTER.DISABLE_SIGN_TOOLTIP')
        : this.$t('CONVERSATION.FOOTER.ENABLE_SIGN_TOOLTIP');
    },
    enableInsertArticleInReply() {
      return this.portalSlug;
    },
    isFetchingAppIntegrations() {
      return this.uiFlags.isFetching;
    },
    quotedReplyToggleTooltip() {
      return this.quotedReplyEnabled
        ? this.$t('CONVERSATION.REPLYBOX.QUOTED_REPLY.DISABLE_TOOLTIP')
        : this.$t('CONVERSATION.REPLYBOX.QUOTED_REPLY.ENABLE_TOOLTIP');
    },
  },
  mounted() {
    ActiveStorage.start();
  },
  methods: {
    toggleMessageSignature() {
      this.setSignatureFlagForInbox(this.channelType, !this.sendWithSignature);
    },
    toggleInsertArticle() {
      this.$emit('toggleInsertArticle');
    },
  },
};
</script>

<template>
  <div
    class="px-3 py-2 flex items-center justify-between border-t border-border bg-muted/20"
  >
    <div class="flex items-center gap-1 flex-wrap">
      <!-- WhatsApp Templates -->
      <NextButton
        v-if="enableWhatsAppTemplates"
        v-tooltip.top-end="$t('CONVERSATION.FOOTER.WHATSAPP_TEMPLATES')"
        icon="i-lucide-message-square"
        variant="ghost"
        class="text-muted-foreground hover:text-foreground h-8 w-8"
        size="icon"
        @click="$emit('selectWhatsappTemplate')"
      />

      <!-- Content Templates -->
      <NextButton
        v-if="enableContentTemplates"
        v-tooltip.top-end="'Content Templates'"
        icon="i-lucide-file-text"
        variant="ghost"
        class="text-muted-foreground hover:text-foreground h-8 w-8"
        size="icon"
        @click="$emit('selectContentTemplate')"
      />

      <!-- Emoji Picker -->
      <NextButton
        v-if="!isEditorDisabled"
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_EMOJI_ICON')"
        icon="i-lucide-smile"
        variant="ghost"
        class="text-muted-foreground hover:text-foreground h-8 w-8"
        size="icon"
        @click="handleEmojiPickerClick"
      />

      <!-- Attach File -->
      <FileUpload
        v-if="showAttachButton"
        ref="uploadRef"
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_ATTACH_ICON')"
        input-id="conversationAttachment"
        :size="4096 * 4096"
        :accept="allowedFileTypes"
        :multiple="enableMultipleFileUpload"
        :drop="enableDragAndDrop"
        :drop-directory="false"
        :data="{
          direct_upload_url: '/rails/active_storage/direct_uploads',
          direct_upload: true,
        }"
        @input-file="onFileUpload"
        class="inline-flex"
      >
        <NextButton
          v-if="!isEditorDisabled"
          v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_ATTACH_ICON')"
          icon="i-lucide-paperclip"
          variant="ghost"
          class="text-muted-foreground hover:text-foreground h-8 w-8"
          size="icon"
        />
      </FileUpload>

      <!-- Audio Recorder -->
      <NextButton
        v-if="!isEditorDisabled"
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_AUDIORECORDER_ICON')"
        :icon="!isRecordingAudio ? 'i-lucide-mic' : 'i-lucide-mic-off'"
        variant="ghost"
        :class="
          isRecordingAudio
            ? 'bg-red-500/10 text-red-500 hover:bg-red-500/20 hover:text-red-600'
            : 'text-muted-foreground hover:text-foreground'
        "
        class="h-8 w-8"
        size="icon"
        @click="toggleAudioRecorder"
      />

      <!-- Audio Play/Pause (only shown when recording) -->
      <NextButton
        v-if="showAudioPlayStopButton"
        :icon="audioRecorderPlayStopIcon"
        variant="ghost"
        class="text-muted-foreground hover:text-foreground h-8 px-2"
        :label="recordingAudioDurationText"
        @click="toggleAudioRecorderPlayPause"
      />

      <!-- Signature -->
      <NextButton
        v-if="!isEditorDisabled"
        v-tooltip.top-end="signatureToggleTooltip"
        icon="i-lucide-pen-line"
        variant="ghost"
        class="text-muted-foreground hover:text-foreground h-8 w-8"
        size="icon"
        @click="toggleMessageSignature"
      />

      <!-- Quoted Reply -->
      <NextButton
        v-if="showQuotedReplyToggle"
        v-tooltip.top-end="quotedReplyToggleTooltip"
        icon="i-lucide-quote"
        :variant="quotedReplyEnabled ? 'solid' : 'ghost'"
        :class="
          quotedReplyEnabled
            ? 'bg-muted text-foreground'
            : 'text-muted-foreground hover:text-foreground'
        "
        class="h-8 w-8"
        size="icon"
        :aria-pressed="quotedReplyEnabled"
        @click="$emit('toggleQuotedReply')"
      />

      <!-- Insert Article -->
      <NextButton
        v-if="!isEditorDisabled"
        v-tooltip.top-end="$t('HELP_CENTER.ARTICLE_SEARCH.OPEN_ARTICLE_SEARCH')"
        icon="i-lucide-file-text"
        variant="ghost"
        class="text-muted-foreground hover:text-foreground h-8 w-8"
        size="icon"
        @click="toggleInsertArticle"
      />

      <!-- AI Reply -->
      <NextButton
        v-if="!isEditorDisabled"
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.AI_REPLY')"
        icon="i-lucide-wand-sparkles"
        variant="ghost"
        class="text-muted-foreground hover:text-foreground h-8 w-8"
        size="icon"
        @click="$emit('toggleCopilot')"
      />

      <!-- Video Call -->
      <VideoCallButton
        v-if="!isEditorDisabled"
        :conversation-id="conversationId"
        class="text-muted-foreground hover:text-foreground h-8 w-8"
      />

      <transition name="modal-fade">
        <div
          v-show="uploadRef && uploadRef.dropActive"
          class="flex fixed top-0 right-0 bottom-0 left-0 z-20 flex-col gap-2 justify-center items-center w-full h-full text-foreground bg-background/80 backdrop-blur-sm"
        >
          <span class="i-lucide-cloud-upload size-10" />
          <h4 class="text-2xl break-words font-medium">
            {{ $t('CONVERSATION.REPLYBOX.DRAG_DROP') }}
          </h4>
        </div>
      </transition>
    </div>

    <!-- Right Side: Send Button -->
    <div class="flex items-center">
      <button
        type="submit"
        class="inline-flex items-center gap-2 h-8 px-4 rounded-md text-sm font-semibold shadow-xs transition-colors disabled:opacity-50 disabled:pointer-events-none"
        :class="
          isNote
            ? 'bg-amber-500 text-white hover:bg-amber-600'
            : 'bg-primary text-primary-foreground hover:bg-primary/90'
        "
        :disabled="isSendDisabled"
        @click="onSend"
      >
        {{ sendButtonText }}
        <span class="i-lucide-corner-down-left size-3.5 opacity-70" />
      </button>
    </div>
  </div>
</template>

<style lang="scss" scoped>
:deep(.file-uploads) {
  label {
    cursor: pointer;
  }
}
</style>
