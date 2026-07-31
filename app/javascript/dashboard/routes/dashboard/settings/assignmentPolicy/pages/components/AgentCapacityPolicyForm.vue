<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import DataTable from 'dashboard/components-next/AssignmentPolicy/components/DataTable.vue';
import AddDataDropdown from 'dashboard/components-next/AssignmentPolicy/components/AddDataDropdown.vue';
import ExclusionRules from 'dashboard/components-next/AssignmentPolicy/components/ExclusionRules.vue';
import InboxCapacityLimits from 'dashboard/components-next/AssignmentPolicy/components/InboxCapacityLimits.vue';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';

const props = defineProps({
  initialData: {
    type: Object,
    default: () => ({
      name: '',
      description: '',
      enabled: false,
      exclusionRules: {
        excludedLabels: [],
        excludeOlderThanHours: null,
      },
      inboxCapacityLimits: [],
    }),
  },
  mode: {
    type: String,
    required: true,
    validator: value => ['CREATE', 'EDIT'].includes(value),
  },
  policyUsers: {
    type: Array,
    default: () => [],
  },
  agentList: {
    type: Array,
    default: () => [],
  },
  labelList: {
    type: Array,
    default: () => [],
  },
  inboxList: {
    type: Array,
    default: () => [],
  },
  showUserSection: {
    type: Boolean,
    default: false,
  },
  showInboxLimitSection: {
    type: Boolean,
    default: false,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  isUsersLoading: {
    type: Boolean,
    default: false,
  },
  isInboxesLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'submit',
  'cancel',
  'addUser',
  'deleteUser',
  'deleteInboxLimit',
  'addInboxLimit',
  'updateInboxLimit',
]);

const { t } = useI18n();

const BASE_KEY = 'ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY';

const state = reactive({
  name: '',
  description: '',
  exclusionRules: {
    excludedLabels: [],
    excludeOlderThanHours: null,
  },
  inboxCapacityLimits: [],
});

const nameTouched = ref(false);

const isNameValid = computed(() => state.name.trim().length > 0);

const buttonLabel = computed(() =>
  t(`${BASE_KEY}.${props.mode.toUpperCase()}.${props.mode}_BUTTON`)
);

const handleDeleteInboxLimit = id => {
  emit('deleteInboxLimit', id);
};

const handleAddInboxLimit = limit => {
  emit('addInboxLimit', limit);
};

const handleLimitChange = limit => {
  emit('updateInboxLimit', limit);
};

const resetForm = () => {
  Object.assign(state, {
    name: '',
    description: '',
    exclusionRules: {
      excludedLabels: [],
      excludeOlderThanHours: null,
    },
    inboxCapacityLimits: [],
  });
  nameTouched.value = false;
};

const handleSubmit = () => {
  nameTouched.value = true;
  if (!isNameValid.value) return;
  emit('submit', { ...state });
};

watch(
  () => props.initialData,
  newData => {
    Object.assign(state, newData);
  },
  { immediate: true, deep: true }
);

defineExpose({
  resetForm,
});
</script>

<template>
  <form class="flex w-full flex-col" @submit.prevent="handleSubmit">
    <div class="space-y-6">
      <div class="flex flex-col gap-1.5">
        <RelayLabel
          html-for="capacity-policy-name"
          class="text-[13.5px] font-medium text-foreground"
        >
          {{ t(`${BASE_KEY}.FORM.NAME.LABEL`) }}
        </RelayLabel>
        <RelayInput
          id="capacity-policy-name"
          v-model="state.name"
          type="text"
          :placeholder="t(`${BASE_KEY}.FORM.NAME.PLACEHOLDER`)"
          class-name="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
          @blur="nameTouched = true"
        />
        <p v-if="nameTouched && !isNameValid" class="text-xs text-destructive">
          {{ t(`${BASE_KEY}.FORM.NAME.ERROR`) }}
        </p>
      </div>

      <div class="flex flex-col gap-1.5">
        <RelayLabel
          html-for="capacity-policy-description"
          class="text-[13.5px] font-medium text-foreground"
        >
          {{ t(`${BASE_KEY}.FORM.DESCRIPTION.LABEL`) }}
          <span class="font-normal text-muted-foreground">
            {{ t(`${BASE_KEY}.FORM.DESCRIPTION.OPTIONAL`) }}
          </span>
        </RelayLabel>
        <RelayInput
          id="capacity-policy-description"
          v-model="state.description"
          type="text"
          :placeholder="t(`${BASE_KEY}.FORM.DESCRIPTION.PLACEHOLDER`)"
          class-name="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
        />
      </div>

      <ExclusionRules
        v-model:excluded-labels="state.exclusionRules.excludedLabels"
        v-model:exclude-older-than-minutes="
          state.exclusionRules.excludeOlderThanHours
        "
        :tags-list="labelList"
      />
    </div>

    <div
      class="mt-8 flex items-center justify-end gap-3 border-t border-border/40 pt-5"
    >
      <RelayButton
        type="button"
        variant="ghost"
        class="h-10 rounded-md border border-border/40 px-5 text-[14px] font-semibold text-muted-foreground hover:border-transparent hover:bg-muted"
        @click="emit('cancel')"
      >
        {{ t(`${BASE_KEY}.FORM.CANCEL_BUTTON`) }}
      </RelayButton>
      <RelayButton
        type="submit"
        class="h-10 rounded-md px-6 text-[14px] font-semibold shadow-sm"
        :disabled="!isNameValid || isLoading"
      >
        {{ buttonLabel }}
      </RelayButton>
    </div>

    <div
      v-if="showInboxLimitSection || showUserSection"
      class="mt-6 flex flex-col gap-4 border-t border-border/40 pt-4"
    >
      <InboxCapacityLimits
        v-if="showInboxLimitSection"
        v-model:inbox-capacity-limits="state.inboxCapacityLimits"
        :inbox-list="inboxList"
        :is-fetching="isInboxesLoading"
        @delete="handleDeleteInboxLimit"
        @add="handleAddInboxLimit"
        @update="handleLimitChange"
      />
      <div v-if="showUserSection" class="flex flex-col gap-4 py-4">
        <div class="flex w-full items-end justify-between gap-4">
          <div class="flex flex-col items-start gap-1 py-1">
            <label class="py-1 text-sm font-medium text-foreground">
              {{ t(`${BASE_KEY}.FORM.USERS.LABEL`) }}
            </label>
            <p class="mb-0 text-sm text-muted-foreground">
              {{ t(`${BASE_KEY}.FORM.USERS.DESCRIPTION`) }}
            </p>
          </div>
          <AddDataDropdown
            :label="t(`${BASE_KEY}.FORM.USERS.ADD_BUTTON`)"
            :search-placeholder="
              t(`${BASE_KEY}.FORM.USERS.DROPDOWN.SEARCH_PLACEHOLDER`)
            "
            :items="agentList"
            @add="$emit('addUser', $event)"
          />
        </div>
        <DataTable
          :items="policyUsers"
          :is-fetching="isUsersLoading"
          :empty-state-message="t(`${BASE_KEY}.FORM.USERS.EMPTY_STATE`)"
          @delete="$emit('deleteUser', $event)"
        />
      </div>
    </div>
  </form>
</template>
