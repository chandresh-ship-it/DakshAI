<script setup>
import { ref, computed } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Auth from '../../../../api/auth';
import wootConstants from 'dashboard/constants/globals';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  name: {
    type: String,
    required: true,
  },
  email: {
    type: String,
    default: '',
  },
  type: {
    type: String,
    default: '',
  },
  availability: {
    type: String,
    default: '',
  },
  provider: {
    type: String,
    default: '',
  },
  customRoleId: {
    type: Number,
    default: null,
  },
});

const emit = defineEmits(['close']);

const { AVAILABILITY_STATUS_KEYS } = wootConstants;

const store = useStore();
const { t } = useI18n();

const agentName = ref(props.name);
const agentAvailability = ref(props.availability);
const selectedRoleId = ref(props.customRoleId || props.type);
const agentCredentials = ref({ email: props.email });

const rules = {
  agentName: { required, minLength: minLength(1) },
  selectedRoleId: { required },
  agentAvailability: { required },
};

const v$ = useVuelidate(rules, {
  agentName,
  selectedRoleId,
  agentAvailability,
});

const pageTitle = computed(
  () => `${t('AGENT_MGMT.EDIT.TITLE')} - ${props.name}`
);

const uiFlags = useMapGetter('agents/getUIFlags');
const getCustomRoles = useMapGetter('customRole/getCustomRoles');

const roles = computed(() => {
  const defaultRoles = [
    {
      id: 'administrator',
      name: 'administrator',
      label: t('AGENT_MGMT.AGENT_TYPES.ADMINISTRATOR'),
    },
    {
      id: 'agent',
      name: 'agent',
      label: t('AGENT_MGMT.AGENT_TYPES.AGENT'),
    },
  ];

  const customRoles = getCustomRoles.value.map(role => ({
    id: role.id,
    name: `custom_${role.id}`,
    label: role.name,
  }));

  return [...defaultRoles, ...customRoles];
});

const selectedRole = computed(() =>
  roles.value.find(
    role =>
      role.id === selectedRoleId.value || role.name === selectedRoleId.value
  )
);

const statusList = computed(() => {
  return [
    t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.ONLINE'),
    t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.BUSY'),
    t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.OFFLINE'),
  ];
});

const availabilityStatuses = computed(() =>
  statusList.value.map((statusLabel, index) => ({
    label: statusLabel,
    value: AVAILABILITY_STATUS_KEYS[index],
  }))
);

const selectClass =
  'flex h-10 w-full appearance-none rounded-md border border-border/80 bg-background px-4 text-[14px] text-foreground shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30';

const editAgent = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  try {
    const payload = {
      id: props.id,
      name: agentName.value,
      availability: agentAvailability.value,
    };

    if (selectedRole.value.name.startsWith('custom_')) {
      payload.custom_role_id = selectedRole.value.id;
    } else {
      payload.role = selectedRole.value.name;
      payload.custom_role_id = null;
    }

    await store.dispatch('agents/update', payload);
    useAlert(t('AGENT_MGMT.EDIT.API.SUCCESS_MESSAGE'));
    emit('close');
  } catch (error) {
    useAlert(t('AGENT_MGMT.EDIT.API.ERROR_MESSAGE'));
  }
};

const resetPassword = async () => {
  try {
    await Auth.resetPassword(agentCredentials.value);
    useAlert(t('AGENT_MGMT.EDIT.PASSWORD_RESET.ADMIN_SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('AGENT_MGMT.EDIT.PASSWORD_RESET.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <div class="flex flex-col overflow-auto p-1">
    <div class="mb-8 relative">
      <h3 class="text-base font-medium text-foreground">
        {{ pageTitle }}
      </h3>
    </div>

    <form class="flex w-full flex-col" @submit.prevent="editAgent">
      <div class="space-y-6">
        <div class="flex flex-col gap-1.5">
          <RelayLabel
            html-for="edit-agent-name"
            class="text-[13.5px] font-medium text-foreground"
          >
            {{ $t('AGENT_MGMT.EDIT.FORM.NAME.LABEL') }}
          </RelayLabel>
          <RelayInput
            id="edit-agent-name"
            v-model="agentName"
            type="text"
            :placeholder="$t('AGENT_MGMT.EDIT.FORM.NAME.PLACEHOLDER')"
            class-name="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
            @blur="v$.agentName.$touch"
          />
          <p v-if="v$.agentName.$error" class="text-xs text-destructive">
            {{ $t('AGENT_MGMT.EDIT.FORM.NAME.ERROR') }}
          </p>
        </div>

        <div class="flex flex-col gap-1.5">
          <RelayLabel
            html-for="edit-agent-role"
            class="text-[13.5px] font-medium text-foreground"
          >
            {{ $t('AGENT_MGMT.EDIT.FORM.AGENT_TYPE.LABEL') }}
          </RelayLabel>
          <div class="relative">
            <select
              id="edit-agent-role"
              v-model="selectedRoleId"
              :class="selectClass"
              @change="v$.selectedRoleId.$touch"
            >
              <option v-for="role in roles" :key="role.id" :value="role.id">
                {{ role.label }}
              </option>
            </select>
            <Icon
              icon="i-lucide-chevron-down"
              class="pointer-events-none absolute top-1/2 size-4 -translate-y-1/2 text-muted-foreground/60 ltr:right-3 rtl:left-3"
            />
          </div>
          <p v-if="v$.selectedRoleId.$error" class="text-xs text-destructive">
            {{ $t('AGENT_MGMT.EDIT.FORM.AGENT_TYPE.ERROR') }}
          </p>
        </div>

        <div class="flex flex-col gap-1.5">
          <RelayLabel
            html-for="edit-agent-availability"
            class="text-[13.5px] font-medium text-foreground"
          >
            {{ $t('AGENT_MGMT.EDIT.FORM.AGENT_AVAILABILITY.LABEL') }}
          </RelayLabel>
          <div class="relative">
            <select
              id="edit-agent-availability"
              v-model="agentAvailability"
              :class="selectClass"
              @change="v$.agentAvailability.$touch"
            >
              <option
                v-for="status in availabilityStatuses"
                :key="status.value"
                :value="status.value"
              >
                {{ status.label }}
              </option>
            </select>
            <Icon
              icon="i-lucide-chevron-down"
              class="pointer-events-none absolute top-1/2 size-4 -translate-y-1/2 text-muted-foreground/60 ltr:right-3 rtl:left-3"
            />
          </div>
          <p
            v-if="v$.agentAvailability.$error"
            class="text-xs text-destructive"
          >
            {{ $t('AGENT_MGMT.EDIT.FORM.AGENT_AVAILABILITY.ERROR') }}
          </p>
        </div>
      </div>

      <div
        class="mt-10 flex items-center justify-between gap-3 border-t border-border/40 pt-6"
      >
        <div>
          <RelayButton
            v-if="provider !== 'saml'"
            type="button"
            variant="ghost"
            class="h-10 rounded-md px-4 text-[13px] font-semibold text-primary hover:bg-primary/10 hover:text-primary"
            @click="resetPassword"
          >
            <Icon icon="i-lucide-lock" class="size-4" />
            {{ $t('AGENT_MGMT.EDIT.PASSWORD_RESET.ADMIN_RESET_BUTTON') }}
          </RelayButton>
        </div>
        <div class="flex items-center gap-3">
          <RelayButton
            type="button"
            variant="ghost"
            class="h-10 rounded-md border border-border/40 px-5 text-[14px] font-semibold text-muted-foreground hover:border-transparent hover:bg-muted"
            @click="emit('close')"
          >
            {{ $t('AGENT_MGMT.EDIT.CANCEL_BUTTON_TEXT') }}
          </RelayButton>
          <RelayButton
            type="submit"
            class="h-10 rounded-md px-6 text-[14px] font-semibold shadow-sm"
            :disabled="v$.$invalid || uiFlags.isUpdating"
          >
            {{ $t('AGENT_MGMT.EDIT.FORM.SUBMIT') }}
          </RelayButton>
        </div>
      </div>
    </form>
  </div>
</template>
