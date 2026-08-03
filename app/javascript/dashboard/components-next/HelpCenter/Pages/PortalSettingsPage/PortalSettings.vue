<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store.js';

import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import PortalBaseSettings from 'dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/PortalBaseSettings.vue';
import PortalConfigurationSettings from './PortalConfigurationSettings.vue';
import PortalLayoutContentSettings from './PortalLayoutContentSettings.vue';
import ConfirmDeletePortalDialog from 'dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/ConfirmDeletePortalDialog.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  portals: {
    type: Array,
    required: true,
  },
  isFetching: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits([
  'updatePortal',
  'updatePortalConfiguration',
  'deletePortal',
  'refreshStatus',
  'sendCnameInstructions',
]);

const { t } = useI18n();
const route = useRoute();

const confirmDeletePortalDialogRef = ref(null);

const currentPortalSlug = computed(() => route.params.portalSlug);

const isSwitchingPortal = useMapGetter('portals/isSwitchingPortal');
const isFetchingSSLStatus = useMapGetter('portals/isFetchingSSLStatus');

const activePortal = computed(() => {
  return props.portals?.find(portal => portal.slug === currentPortalSlug.value);
});

const activePortalName = computed(() => activePortal.value?.name || '');

const isLoading = computed(() => props.isFetching || isSwitchingPortal.value);

const handleUpdatePortal = portal => {
  emit('updatePortal', portal);
};

const handleUpdatePortalConfiguration = portal => {
  emit('updatePortalConfiguration', portal);
};

const fetchSSLStatus = () => {
  emit('refreshStatus');
};

const handleSendCnameInstructions = payload => {
  emit('sendCnameInstructions', payload);
};

const openConfirmDeletePortalDialog = () => {
  confirmDeletePortalDialogRef.value.dialogRef.open();
};

const handleDeletePortal = () => {
  emit('deletePortal', activePortal.value);
  confirmDeletePortalDialogRef.value.dialogRef.close();
};
</script>

<template>
  <HelpCenterLayout :show-pagination-footer="false">
    <template #content>
      <div
        v-if="isLoading"
        class="flex items-center justify-center py-10 text-muted-foreground"
      >
        <Spinner />
      </div>
      <div
        v-else-if="activePortal"
        class="flex w-full max-w-3xl flex-col gap-6 pb-8"
      >
        <PortalBaseSettings
          :active-portal="activePortal"
          :is-fetching="isFetching"
          @update-portal="handleUpdatePortal"
        />
        <PortalConfigurationSettings
          :active-portal="activePortal"
          :is-fetching="isFetching"
          :is-fetching-status="isFetchingSSLStatus"
          @update-portal-configuration="handleUpdatePortalConfiguration"
          @refresh-status="fetchSSLStatus"
          @send-cname-instructions="handleSendCnameInstructions"
        />
        <PortalLayoutContentSettings
          :active-portal="activePortal"
          :is-fetching="isFetching"
          @update-portal-configuration="handleUpdatePortalConfiguration"
        />
        <div
          class="flex w-full items-end justify-between gap-4 rounded-2xl border border-border/40 bg-card p-6 shadow-sm"
        >
          <div class="flex flex-col gap-2">
            <h6 class="text-base font-medium text-foreground">
              {{
                t(
                  'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.DELETE_PORTAL.HEADER'
                )
              }}
            </h6>
            <span class="text-sm text-muted-foreground">
              {{
                t(
                  'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.DELETE_PORTAL.DESCRIPTION'
                )
              }}
            </span>
          </div>
          <RelayButton
            variant="destructive"
            class="h-9 max-w-56 shrink-0"
            @click="openConfirmDeletePortalDialog"
          >
            {{
              t(
                'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.DELETE_PORTAL.BUTTON',
                {
                  portalName: activePortalName,
                }
              )
            }}
          </RelayButton>
        </div>
      </div>
    </template>
    <ConfirmDeletePortalDialog
      ref="confirmDeletePortalDialogRef"
      :active-portal-name="activePortalName"
      @delete-portal="handleDeletePortal"
    />
  </HelpCenterLayout>
</template>
