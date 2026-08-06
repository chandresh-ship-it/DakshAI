<script>
import { ref } from 'vue';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { useTrack } from 'dashboard/composables';
import { vOnClickOutside } from '@vueuse/components';
import { REPLY_EDITOR_MODES, CHAR_LENGTH_WARNING } from './constants';
import { CAPTAIN_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import NextButton from 'dashboard/components-next/button/Button.vue';
import CopilotMenuBar from './CopilotMenuBar.vue';

export default {
  name: 'ReplyTopPanel',
  components: {
    NextButton,
    CopilotMenuBar,
  },
  directives: {
    OnClickOutside: vOnClickOutside,
  },
  props: {
    mode: {
      type: String,
      default: REPLY_EDITOR_MODES.REPLY,
    },
    isReplyRestricted: {
      type: Boolean,
      default: false,
    },
    disabled: {
      type: Boolean,
      default: false,
    },
    isEditorDisabled: {
      type: Boolean,
      default: false,
    },
    conversationId: {
      type: Number,
      default: null,
    },
    isMessageLengthReachingThreshold: {
      type: Boolean,
      default: () => false,
    },
    charactersRemaining: {
      type: Number,
      default: () => 0,
    },
    editorContent: {
      type: String,
      default: undefined,
    },
    hasContent: {
      type: Boolean,
      default: false,
    },
    isCopilotActive: {
      type: Boolean,
      default: false,
    },
    contactName: {
      type: String,
      default: '',
    },
  },
  emits: [
    'setReplyMode',
    'toggleEditorSize',
    'executeCopilotAction',
    'toggleCopilot',
    'resetCopilot',
  ],
  setup(props, { emit }) {
    const setReplyMode = mode => {
      emit('setReplyMode', mode);
    };
    const handleReplyClick = () => {
      if (props.isReplyRestricted) return;
      if (props.isCopilotActive) {
        emit('resetCopilot');
      }
      setReplyMode(REPLY_EDITOR_MODES.REPLY);
    };
    const handleNoteClick = () => {
      if (props.isCopilotActive) {
        emit('resetCopilot');
      }
      setReplyMode(REPLY_EDITOR_MODES.NOTE);
    };
    const handleAiReplyClick = () => {
      if (props.disabled || props.isEditorDisabled) return;
      if (!props.isCopilotActive) {
        if (props.mode !== REPLY_EDITOR_MODES.REPLY) {
          setReplyMode(REPLY_EDITOR_MODES.REPLY);
        }
        emit('toggleCopilot');
      }
    };

    const { captainTasksEnabled } = useCaptain();
    const showCopilotMenu = ref(false);
    const copilotToggleRef = ref(null);

    const handleCopilotAction = (actionKey, data) => {
      emit('executeCopilotAction', actionKey, data || props.editorContent);
      showCopilotMenu.value = false;
    };

    const toggleCopilotMenu = () => {
      const isOpening = !showCopilotMenu.value;
      if (isOpening) {
        useTrack(CAPTAIN_EVENTS.EDITOR_AI_MENU_OPENED, {
          conversationId: props.conversationId,
          entryPoint: 'top_panel',
        });
      }
      showCopilotMenu.value = isOpening;
    };

    const handleClickOutside = () => {
      showCopilotMenu.value = false;
    };

    const keyboardEvents = {
      'Alt+KeyP': {
        action: () => handleNoteClick(),
        allowOnFocusedInput: false,
      },
      'Alt+KeyL': {
        action: () => handleReplyClick(),
        allowOnFocusedInput: false,
      },
    };
    useKeyboardEvents(keyboardEvents);

    return {
      handleReplyClick,
      handleNoteClick,
      handleAiReplyClick,
      REPLY_EDITOR_MODES,
      captainTasksEnabled,
      handleCopilotAction,
      showCopilotMenu,
      copilotToggleRef,
      toggleCopilotMenu,
      handleClickOutside,
    };
  },
  computed: {
    isReplyActive() {
      return (
        this.mode === REPLY_EDITOR_MODES.REPLY &&
        !this.isCopilotActive &&
        !this.isReplyRestricted
      );
    },
    isNoteActive() {
      return this.mode === REPLY_EDITOR_MODES.NOTE || this.isReplyRestricted;
    },
    isAiActive() {
      return this.isCopilotActive;
    },
    charLengthClass() {
      return this.charactersRemaining < 0
        ? 'text-destructive'
        : 'text-muted-foreground';
    },
    characterLengthWarning() {
      return this.charactersRemaining < 0
        ? `${-this.charactersRemaining} ${CHAR_LENGTH_WARNING.NEGATIVE}`
        : `${this.charactersRemaining} ${CHAR_LENGTH_WARNING.UNDER_50}`;
    },
  },
};
</script>

<template>
  <div
    class="flex items-center justify-between h-10 px-4 border-b border-border gap-4 bg-background"
    role="tablist"
  >
    <div class="flex items-center gap-6 h-full">
      <button
        type="button"
        role="tab"
        :aria-selected="isReplyActive"
        class="relative h-full px-0 text-sm font-semibold transition-colors"
        :class="
          isReplyActive
            ? 'text-foreground'
            : 'text-muted-foreground hover:text-foreground'
        "
        :disabled="disabled || isReplyRestricted"
        @click="handleReplyClick"
      >
        {{
          contactName
            ? `Reply to ${contactName}`
            : $t('CONVERSATION.REPLYBOX.REPLY')
        }}
        <span
          v-if="isReplyActive"
          class="absolute inset-x-0 bottom-0 h-0.5 bg-primary"
          aria-hidden="true"
        />
      </button>
      <button
        type="button"
        role="tab"
        :aria-selected="isNoteActive"
        class="relative h-full px-0 text-sm font-semibold transition-colors"
        :class="
          isNoteActive
            ? 'text-amber-500'
            : 'text-muted-foreground hover:text-foreground'
        "
        :disabled="disabled"
        @click="handleNoteClick"
      >
        {{ $t('CONVERSATION.REPLYBOX.PRIVATE_NOTE') }}
        <span
          v-if="isNoteActive"
          class="absolute inset-x-0 bottom-0 h-0.5 bg-amber-500"
          aria-hidden="true"
        />
      </button>
      <button
        v-if="captainTasksEnabled"
        type="button"
        role="tab"
        :aria-selected="isAiActive"
        class="relative h-full px-0 text-sm font-semibold transition-colors inline-flex items-center gap-1.5"
        :class="
          isAiActive
            ? 'text-primary'
            : 'text-muted-foreground hover:text-foreground'
        "
        :disabled="disabled || isEditorDisabled"
        @click="handleAiReplyClick"
      >
        <span class="i-lucide-wand-sparkles size-4" />
        {{ $t('CONVERSATION.REPLYBOX.AI_REPLY') }}
        <span
          v-if="isAiActive"
          class="absolute inset-x-0 bottom-0 h-0.5 bg-primary"
          aria-hidden="true"
        />
      </button>
    </div>
    <div class="flex items-center gap-2">
      <div v-if="isMessageLengthReachingThreshold" class="text-xs">
        <span :class="charLengthClass">
          {{ characterLengthWarning }}
        </span>
      </div>
      <div v-if="captainTasksEnabled" class="relative">
        <div ref="copilotToggleRef" class="inline-flex">
          <NextButton
            ghost
            :disabled="disabled || isEditorDisabled"
            sm
            icon="i-ph-sparkle-fill"
            class="text-muted-foreground"
            @click="toggleCopilotMenu"
          />
        </div>
        <CopilotMenuBar
          v-if="showCopilotMenu"
          v-on-click-outside="[
            handleClickOutside,
            { ignore: [copilotToggleRef] },
          ]"
          :has-selection="false"
          :has-content="hasContent"
          :conversation-id="conversationId"
          class="ltr:right-0 rtl:left-0 bottom-full mb-2"
          @execute-copilot-action="handleCopilotAction"
        />
      </div>
      <NextButton
        ghost
        class="text-muted-foreground"
        sm
        icon="i-lucide-maximize-2"
        @click="$emit('toggleEditorSize')"
      />
    </div>
  </div>
</template>
