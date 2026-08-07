<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import {
  DuplicateContactException,
  ExceptionWithMessage,
} from 'shared/helpers/CustomErrors';
import { useAdmin } from 'dashboard/composables/useAdmin';
import Avatar from 'next/avatar/Avatar.vue';
import SocialIcons from './SocialIcons.vue';
import EditContact from './EditContact.vue';
import ContactMergeModal from 'dashboard/modules/contact/ContactMergeModal.vue';
import ContactDeleteModal from 'dashboard/modules/contact/ContactDeleteModal.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import VoiceCallButton from 'dashboard/components-next/Contacts/VoiceCallButton.vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';

export default {
  components: {
    NextButton,
    EditContact,
    Avatar,
    ComposeConversation,
    SocialIcons,
    ContactMergeModal,
    ContactDeleteModal,
    VoiceCallButton,
    InlineInput,
  },
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
    showAvatar: {
      type: Boolean,
      default: true,
    },
  },
  emits: ['panelClose'],
  setup() {
    const { isAdmin } = useAdmin();
    return {
      isAdmin,
    };
  },
  data() {
    return {
      showEditModal: false,
      isEditingName: false,
      editName: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
      currentChat: 'getSelectedChat',
    }),
    contactProfileLink() {
      return `/app/accounts/${this.$route.params.accountId}/contacts/${this.contact.id}`;
    },
    additionalAttributes() {
      return this.contact.additional_attributes || {};
    },
    location() {
      const {
        country = '',
        city = '',
        country_code: countryCode,
      } = this.additionalAttributes;
      const cityAndCountry = [city, country].filter(item => !!item).join(', ');

      if (!cityAndCountry) {
        return '';
      }
      return this.findCountryFlag(countryCode, cityAndCountry);
    },
    socialProfiles() {
      const {
        social_profiles: socialProfiles,
        screen_name: twitterScreenName,
        social_telegram_user_name: telegramUsername,
      } = this.additionalAttributes;

      const telegram = socialProfiles?.telegram || telegramUsername || '';
      const twitter = socialProfiles?.twitter || twitterScreenName || '';

      return {
        ...(socialProfiles || {}),
        twitter,
        telegram,
      };
    },
  },
  watch: {
    'contact.id': {
      handler(id) {
        this.$store.dispatch('contacts/fetchContactableInbox', id);
      },
      immediate: true,
    },
  },
  methods: {
    toggleEditModal() {
      this.showEditModal = !this.showEditModal;
    },
    findCountryFlag(countryCode, cityAndCountry) {
      try {
        if (!countryCode) {
          return `${cityAndCountry} 🌎`;
        }

        const code = countryCode?.toLowerCase();
        return `${cityAndCountry} <span class="fi fi-${code} size-3.5"></span>`;
      } catch (error) {
        return '';
      }
    },
    startEditingName() {
      this.editName = this.contact.name || '';
      this.isEditingName = true;
      this.$nextTick(() => {
        this.$refs.nameInput?.focus();
      });
    },
    saveNameEdit() {
      if (!this.isEditingName) return;
      this.isEditingName = false;
      const trimmed = this.editName.trim();
      if (trimmed && trimmed !== this.contact.name) {
        this.updateContactField({ name: trimmed });
      }
    },
    cancelNameEdit() {
      this.isEditingName = false;
    },
    onFieldUpdate(field, value) {
      this.updateContactField({ [field]: value });
    },
    async updateContactField(attrs) {
      const contactId = this.contact.id;
      try {
        await this.$store.dispatch('contacts/update', {
          id: contactId,
          ...attrs,
        });
        useAlert(this.$t('CONTACT_FORM.SUCCESS_MESSAGE'));
        await this.$store.dispatch('contacts/fetchContactableInbox', contactId);
      } catch (error) {
        if (error instanceof DuplicateContactException) {
          const detail = error.contactErrorDetail;
          if (detail) {
            useAlert(detail);
          } else {
            const invalidAttrs = Array.isArray(error.data) ? error.data : [];
            if (invalidAttrs.includes('email')) {
              useAlert(this.$t('CONTACT_FORM.FORM.EMAIL_ADDRESS.DUPLICATE'));
            } else if (invalidAttrs.includes('phone_number')) {
              useAlert(this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.DUPLICATE'));
            } else {
              useAlert(this.$t('CONTACT_FORM.ERROR_MESSAGE'));
            }
          }
        } else if (error instanceof ExceptionWithMessage) {
          useAlert(error.data);
        } else {
          useAlert(error.message || this.$t('CONTACT_FORM.ERROR_MESSAGE'));
        }
      }
    },
  },
};
</script>

<template>
  <div
    class="relative w-full bg-card border border-border/60 rounded-xl p-5 shadow-sm flex flex-col"
  >
    <!-- Header -->
    <div class="flex w-full justify-between items-center mb-6">
      <h3 class="text-base font-medium text-foreground">
        {{ $t('CONVERSATION.SIDEBAR.OVERVIEW') }}
      </h3>
      <a
        :href="contactProfileLink"
        target="_blank"
        rel="noopener nofollow noreferrer"
        class="flex items-center gap-1.5 px-3 py-1.5 bg-primary/10 text-primary text-[13px] font-medium rounded-md hover:bg-primary/20 transition-colors"
      >
        {{ $t('CONVERSATION.SIDEBAR.VIEW_FULL_PROFILE') }}
        <span class="i-lucide-arrow-up-right size-3.5 shrink-0" />
      </a>
    </div>

    <!-- Details -->
    <div class="flex flex-col w-full">
      <!-- Avatar & Name -->
      <div class="flex items-center gap-4 mb-4">
        <div class="relative shrink-0">
          <Avatar
            v-if="showAvatar"
            :src="contact.thumbnail"
            :name="contact.name"
            :size="64"
            hide-offline-status
            rounded-full
          />
          <!-- Online status dot overlay -->
          <div
            v-if="contact.availability_status === 'online'"
            class="absolute bottom-0 right-0 size-3.5 bg-[var(--success)] border-[2.5px] border-background rounded-full"
          />
        </div>
        <div class="min-w-0 flex-1 flex flex-col gap-0.5">
          <InlineInput
            v-if="isEditingName"
            ref="nameInput"
            v-model="editName"
            custom-input-class="!text-[15px] !font-semibold"
            class="!w-fit"
            @enter-press="saveNameEdit"
            @escape-press="cancelNameEdit"
            @blur="saveNameEdit"
          />
          <h2
            v-else-if="showAvatar"
            class="group/name text-[15px] font-semibold text-foreground truncate cursor-pointer hover:text-primary transition-colors leading-tight"
            :title="$t('CONTACT_PANEL.CLICK_TO_EDIT')"
            @click="startEditingName"
          >
            {{ contact.name }}
          </h2>
          <p class="text-[13px] text-muted-foreground truncate">
            {{ additionalAttributes.company_plan || 'Enterprise Plan' }}
          </p>
        </div>
      </div>

      <div class="h-px bg-border/60 w-full mb-4" />

      <!-- Contact Metadata -->
      <div class="flex flex-col gap-2 min-w-0">
        <div v-if="contact.email" class="flex items-center gap-3">
          <div
            class="size-8 rounded-lg bg-primary/10 flex items-center justify-center text-primary shrink-0"
          >
            <span class="i-lucide-mail size-4" />
          </div>
          <span class="text-[13px] text-foreground truncate">{{
            contact.email
          }}</span>
        </div>

        <div v-if="contact.phone_number" class="flex items-center gap-3">
          <div
            class="size-8 rounded-lg bg-primary/10 flex items-center justify-center text-primary shrink-0"
          >
            <span class="i-lucide-phone size-4" />
          </div>
          <span class="text-[13px] text-foreground truncate">{{
            contact.phone_number
          }}</span>
        </div>

        <div
          v-if="location || additionalAttributes.location"
          class="flex items-center gap-3"
        >
          <div
            class="size-8 rounded-lg bg-primary/10 flex items-center justify-center text-primary shrink-0"
          >
            <span class="i-lucide-map-pin size-4" />
          </div>
          <span
            class="text-[13px] text-foreground truncate"
            v-html="location || additionalAttributes.location"
          />
        </div>

        <div v-if="socialProfiles" class="mt-1">
          <SocialIcons :social-profiles="socialProfiles" />
        </div>
      </div>
    </div>

    <!-- Actions (hidden in screenshot, kept for functionality) -->
    <div class="flex flex-wrap items-center gap-2 mt-6">
      <ComposeConversation :contact-id="String(contact.id)">
        <template #trigger>
          <NextButton
            v-tooltip.top-end="$t('CONTACT_PANEL.NEW_MESSAGE')"
            icon="i-ph-chat-circle-dots"
            slate
            faded
            sm
          />
        </template>
      </ComposeConversation>
      <VoiceCallButton
        :phone="contact.phone_number"
        :contact-id="contact.id"
        :conversation-id="currentChat?.id"
        icon="i-lucide-phone"
        sm
        faded
        slate
        :tooltip-label="$t('CONTACT_PANEL.CALL')"
      />
      <NextButton
        v-tooltip.top-end="$t('EDIT_CONTACT.BUTTON_LABEL')"
        icon="i-ph-pencil-simple"
        slate
        faded
        sm
        @click="toggleEditModal"
      />
      <ContactMergeModal :primary-contact="contact">
        <template #trigger>
          <NextButton
            v-tooltip.top-end="$t('CONTACT_PANEL.MERGE_CONTACT')"
            icon="i-ph-arrows-merge"
            slate
            faded
            sm
            :disabled="uiFlags.isMerging"
          />
        </template>
      </ContactMergeModal>
      <ContactDeleteModal
        v-if="isAdmin"
        :contact="contact"
        @deleted="$emit('panelClose')"
      >
        <template #trigger>
          <NextButton
            v-tooltip.top-end="$t('DELETE_CONTACT.BUTTON_LABEL')"
            icon="i-ph-trash"
            slate
            faded
            sm
            ruby
            :disabled="uiFlags.isDeleting"
          />
        </template>
      </ContactDeleteModal>
    </div>

    <EditContact
      :show="showEditModal"
      :contact="contact"
      @cancel="toggleEditModal"
    />
  </div>
</template>
