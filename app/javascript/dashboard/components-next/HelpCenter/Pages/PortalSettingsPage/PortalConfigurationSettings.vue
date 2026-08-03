<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';

import AddCustomDomainDialog from 'dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/AddCustomDomainDialog.vue';
import DNSConfigurationDialog from 'dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/DNSConfigurationDialog.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  activePortal: {
    type: Object,
    required: true,
  },
  isFetchingStatus: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits([
  'updatePortalConfiguration',
  'refreshStatus',
  'sendCnameInstructions',
]);

const SSL_STATUS = {
  LIVE: ['active', 'staging_active'],
  PENDING: [
    'provisioned',
    'pending',
    'initializing',
    'pending_validation',
    'pending_deployment',
    'pending_issuance',
    'holding_deployment',
    'holding_validation',
    'pending_expiration',
    'pending_cleanup',
    'pending_deletion',
    'staging_deployment',
    'backup_issued',
  ],
  ERROR: [
    'blocked',
    'inactive',
    'moved',
    'expired',
    'deleted',
    'timed_out_initializing',
    'timed_out_validation',
    'timed_out_issuance',
    'timed_out_deployment',
    'timed_out_deletion',
    'deactivating',
  ],
};

const { t } = useI18n();
const { isOnChatwootCloud } = useAccount();

const addCustomDomainDialogRef = ref(null);
const dnsConfigurationDialogRef = ref(null);
const updatedDomainAddress = ref('');

const customDomainAddress = computed(
  () => props.activePortal?.custom_domain || ''
);

const sslSettings = computed(() => props.activePortal?.ssl_settings || {});
const verificationErrors = computed(
  () => sslSettings.value.verification_errors || ''
);

const isLive = computed(() =>
  SSL_STATUS.LIVE.includes(sslSettings.value.status)
);
const isPending = computed(() =>
  SSL_STATUS.PENDING.includes(sslSettings.value.status)
);
const isError = computed(() =>
  SSL_STATUS.ERROR.includes(sslSettings.value.status)
);

const statusText = computed(() => {
  if (isLive.value)
    return t(
      'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.STATUS.LIVE'
    );
  if (isPending.value)
    return t(
      'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.STATUS.PENDING'
    );
  if (isError.value)
    return t(
      'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.STATUS.ERROR'
    );
  return '';
});

const statusColors = computed(() => {
  if (isLive.value)
    return { text: 'text-primary', bubble: 'outline-primary/30 bg-primary' };
  if (isError.value)
    return {
      text: 'text-destructive',
      bubble: 'outline-destructive/30 bg-destructive',
    };
  return {
    text: 'text-amber-600',
    bubble: 'outline-amber-500/30 bg-amber-500',
  };
});

const updatePortalConfiguration = customDomain => {
  const portal = {
    id: props.activePortal?.id,
    custom_domain: customDomain,
  };
  emit('updatePortalConfiguration', portal);
  addCustomDomainDialogRef.value.dialogRef.close();
  if (customDomain) {
    updatedDomainAddress.value = customDomain;
    dnsConfigurationDialogRef.value.dialogRef.open();
  }
};

const closeDNSConfigurationDialog = () => {
  updatedDomainAddress.value = '';
  dnsConfigurationDialogRef.value.dialogRef.close();
};

const onClickRefreshSSLStatus = () => {
  emit('refreshStatus');
};

const onClickSend = email => {
  emit('sendCnameInstructions', {
    portalSlug: props.activePortal?.slug,
    email,
  });
};
</script>

<template>
  <div
    class="flex flex-col gap-6 rounded-2xl border border-border/40 bg-card p-6 shadow-sm"
  >
    <div class="flex flex-col gap-2">
      <h6 class="text-base font-medium text-foreground">
        {{
          t(
            'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.HEADER'
          )
        }}
      </h6>
      <span class="text-sm text-muted-foreground">
        {{
          t(
            'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DESCRIPTION'
          )
        }}
      </span>
    </div>
    <div class="flex flex-col gap-4">
      <div class="flex w-full items-center justify-between gap-2">
        <div v-if="customDomainAddress" class="flex flex-col gap-1">
          <div class="flex h-8 w-full items-center gap-4">
            <label class="text-sm font-medium text-foreground">
              {{
                t(
                  'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.LABEL'
                )
              }}
            </label>
            <span class="text-sm text-foreground">
              {{ customDomainAddress }}
            </span>
          </div>
          <span
            v-if="!isLive && isOnChatwootCloud"
            class="text-sm text-muted-foreground"
          >
            {{
              t(
                'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.STATUS_DESCRIPTION'
              )
            }}
          </span>
        </div>
        <div class="flex items-center">
          <div v-if="customDomainAddress" class="flex items-center gap-3">
            <div
              v-if="statusText && isOnChatwootCloud"
              v-tooltip="verificationErrors"
              class="flex flex-shrink-0 items-center gap-3"
            >
              <span
                class="block size-1.5 flex-shrink-0 rounded-full outline outline-2"
                :class="statusColors.bubble"
              />
              <span
                :class="statusColors.text"
                class="text-sm font-medium leading-[16px]"
              >
                {{ statusText }}
              </span>
            </div>
            <div
              v-if="statusText && isOnChatwootCloud"
              class="h-3 w-px bg-border"
            />
            <RelayButton
              variant="link"
              size="sm"
              class="h-auto flex-shrink-0 p-0"
              @click="addCustomDomainDialogRef.dialogRef.open()"
            >
              {{
                t(
                  'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.EDIT_BUTTON'
                )
              }}
            </RelayButton>
            <div v-if="isOnChatwootCloud" class="h-3 w-px bg-border" />
            <RelayButton
              v-if="isOnChatwootCloud"
              variant="ghost"
              size="icon"
              class="size-8 text-muted-foreground"
              :class="isFetchingStatus && 'animate-spin'"
              @click="onClickRefreshSSLStatus"
            >
              <span class="i-lucide-refresh-ccw size-4" />
            </RelayButton>
          </div>
          <RelayButton
            v-else
            variant="outline"
            @click="addCustomDomainDialogRef.dialogRef.open()"
          >
            {{
              t(
                'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.ADD_BUTTON'
              )
            }}
          </RelayButton>
        </div>
      </div>
    </div>
    <AddCustomDomainDialog
      ref="addCustomDomainDialogRef"
      :mode="customDomainAddress ? 'edit' : 'add'"
      :custom-domain="customDomainAddress"
      @add-custom-domain="updatePortalConfiguration"
    />
    <DNSConfigurationDialog
      ref="dnsConfigurationDialogRef"
      :custom-domain="updatedDomainAddress || customDomainAddress"
      @close="closeDNSConfigurationDialog"
      @send="onClickSend"
    />
  </div>
</template>
