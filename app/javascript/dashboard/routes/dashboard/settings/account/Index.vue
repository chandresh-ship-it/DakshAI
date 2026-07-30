<script>
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useConfig } from 'dashboard/composables/useConfig';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from '../../../../featureFlags';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextInput from 'next/input/Input.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import AccountId from './components/AccountId.vue';
import BuildInfo from './components/BuildInfo.vue';
import AccountDelete from './components/AccountDelete.vue';
import AudioTranscription from './components/AudioTranscription.vue';
import SectionLayout from './components/SectionLayout.vue';

export default {
  components: {
    BaseSettingsHeader,
    RelayButton,
    ComboBox,
    AccountId,
    BuildInfo,
    AccountDelete,
    AudioTranscription,
    SectionLayout,
    WithLabel,
    NextInput,
  },
  setup() {
    const { updateUISettings, uiSettings } = useUISettings();
    const { enabledLanguages } = useConfig();
    const { accountId } = useAccount();
    const v$ = useVuelidate();

    return { updateUISettings, uiSettings, v$, enabledLanguages, accountId };
  },
  data() {
    return {
      id: '',
      name: '',
      locale: 'en',
      domain: '',
      supportEmail: '',
      features: {},
    };
  },
  validations: {
    name: {
      required,
    },
    locale: {
      required,
    },
  },
  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
      uiFlags: 'accounts/getUIFlags',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
      isOnChatwootCloud: 'globalConfig/isOnChatwootCloud',
    }),
    showAudioTranscriptionConfig() {
      return this.isFeatureEnabledonAccount(
        this.accountId,
        FEATURE_FLAGS.CAPTAIN
      );
    },
    languagesSortedByCode() {
      const enabledLanguages = [...this.enabledLanguages];
      return enabledLanguages.sort((l1, l2) =>
        l1.iso_639_1_code.localeCompare(l2.iso_639_1_code)
      );
    },
    languageOptions() {
      return this.languagesSortedByCode.map(lang => ({
        value: lang.iso_639_1_code,
        label: lang.name,
      }));
    },
    isUpdating() {
      return this.uiFlags.isUpdating;
    },
    featureInboundEmailEnabled() {
      return !!this.features?.inbound_emails;
    },
    featureCustomReplyDomainEnabled() {
      return (
        this.featureInboundEmailEnabled && !!this.features.custom_reply_domain
      );
    },
    featureCustomReplyEmailEnabled() {
      return (
        this.featureInboundEmailEnabled && !!this.features.custom_reply_email
      );
    },
    currentAccount() {
      return this.getAccount(this.accountId) || {};
    },
  },
  mounted() {
    this.initializeAccount();
  },
  methods: {
    async initializeAccount() {
      try {
        const { name, locale, id, domain, support_email, features } =
          this.getAccount(this.accountId);

        const effectiveLocale = this.uiSettings?.locale || locale;
        if (effectiveLocale) {
          this.$root.$i18n.locale = effectiveLocale;
        }
        this.name = name;
        this.locale = locale;
        this.id = id;
        this.domain = domain;
        this.supportEmail = support_email;
        this.features = features;
      } catch (error) {
        // Ignore error
      }
    },

    handleCancel() {
      this.initializeAccount();
    },

    async updateAccount() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        useAlert(this.$t('GENERAL_SETTINGS.FORM.ERROR'));
        return;
      }
      try {
        await this.$store.dispatch('accounts/update', {
          locale: this.locale,
          name: this.name,
          domain: this.domain,
          support_email: this.supportEmail,
        });
        // If user locale is set, update the locale with user locale
        const updatedLocale = this.uiSettings?.locale || this.locale;
        if (updatedLocale) {
          this.$root.$i18n.locale = updatedLocale;
        }
        this.getAccount(this.id).locale = this.locale;
        useAlert(this.$t('GENERAL_SETTINGS.UPDATE.SUCCESS'));
      } catch (error) {
        useAlert(this.$t('GENERAL_SETTINGS.UPDATE.ERROR'));
      }
    },
    onLocaleChange(value) {
      // ComboBox clears on re-select; keep required locale set
      if (value) {
        this.locale = value;
      }
    },
  },
};
</script>

<template>
  <div class="flex w-full max-w-3xl flex-col gap-8 ltr:mr-auto rtl:ml-auto">
    <BaseSettingsHeader :title="$t('GENERAL_SETTINGS.TITLE')" />
    <form
      v-if="!uiFlags.isFetchingItem"
      class="flex min-w-0 flex-col gap-8"
      @submit.prevent="updateAccount"
    >
      <SectionLayout
        :title="$t('GENERAL_SETTINGS.FORM.GENERAL_SECTION.TITLE')"
        :description="$t('GENERAL_SETTINGS.FORM.GENERAL_SECTION.NOTE')"
        icon="i-lucide-clipboard-list"
        as-card
      >
        <div class="grid gap-8">
          <div class="grid grid-cols-1 gap-8 md:grid-cols-2">
            <WithLabel
              name="account-name"
              :has-error="v$.name.$error"
              :label="$t('GENERAL_SETTINGS.FORM.NAME.LABEL')"
              :error-message="$t('GENERAL_SETTINGS.FORM.NAME.ERROR')"
            >
              <NextInput
                v-model="name"
                type="text"
                class="w-full"
                :placeholder="$t('GENERAL_SETTINGS.FORM.NAME.PLACEHOLDER')"
                @blur="v$.name.$touch"
              />
            </WithLabel>
            <WithLabel
              name="site-language"
              :has-error="v$.locale.$error"
              :label="$t('GENERAL_SETTINGS.FORM.LANGUAGE.LABEL')"
              :error-message="$t('GENERAL_SETTINGS.FORM.LANGUAGE.ERROR')"
            >
              <ComboBox
                :model-value="locale"
                :options="languageOptions"
                :placeholder="$t('GENERAL_SETTINGS.FORM.LANGUAGE.PLACEHOLDER')"
                :search-placeholder="
                  $t('GENERAL_SETTINGS.FORM.LANGUAGE.SEARCH_PLACEHOLDER')
                "
                :has-error="v$.locale.$error"
                class="w-full [&>div>button]:!h-10 [&>div>button]:!rounded-md [&>div>button]:!border-input [&>div>button]:!bg-background [&>div>button]:!shadow-xs [&>div>button]:!text-foreground [&>div>button]:font-normal"
                @update:model-value="onLocaleChange"
              />
            </WithLabel>
          </div>
          <div
            v-if="
              featureCustomReplyDomainEnabled || featureCustomReplyEmailEnabled
            "
            class="grid grid-cols-1 gap-8 md:grid-cols-2"
          >
            <WithLabel
              v-if="featureCustomReplyDomainEnabled"
              name="custom-domain"
              :label="$t('GENERAL_SETTINGS.FORM.DOMAIN.LABEL')"
            >
              <NextInput
                v-model="domain"
                type="text"
                class="w-full"
                :placeholder="$t('GENERAL_SETTINGS.FORM.DOMAIN.PLACEHOLDER')"
              />
              <template #help>
                {{
                  featureInboundEmailEnabled &&
                  $t('GENERAL_SETTINGS.FORM.FEATURES.INBOUND_EMAIL_ENABLED')
                }}

                {{
                  featureCustomReplyDomainEnabled &&
                  $t(
                    'GENERAL_SETTINGS.FORM.FEATURES.CUSTOM_EMAIL_DOMAIN_ENABLED'
                  )
                }}
              </template>
            </WithLabel>
            <WithLabel
              v-if="featureCustomReplyEmailEnabled"
              name="support-email"
              :label="$t('GENERAL_SETTINGS.FORM.SUPPORT_EMAIL.LABEL')"
            >
              <NextInput
                v-model="supportEmail"
                type="text"
                class="w-full"
                :placeholder="
                  $t('GENERAL_SETTINGS.FORM.SUPPORT_EMAIL.PLACEHOLDER')
                "
              />
            </WithLabel>
          </div>
        </div>
      </SectionLayout>

      <AudioTranscription v-if="showAudioTranscriptionConfig" />
      <AccountId />
      <AccountDelete v-if="isOnChatwootCloud" />

      <div class="flex justify-end gap-3 border-t border-border/40 pb-2 pt-8">
        <RelayButton
          variant="outline"
          type="button"
          :disabled="isUpdating"
          @click="handleCancel"
        >
          {{ $t('GENERAL_SETTINGS.CANCEL') }}
        </RelayButton>
        <RelayButton :disabled="isUpdating" type="submit" class="shadow-sm">
          {{ $t('GENERAL_SETTINGS.SUBMIT') }}
        </RelayButton>
      </div>
    </form>
    <woot-loading-state v-if="uiFlags.isFetchingItem" />
    <BuildInfo />
  </div>
</template>
