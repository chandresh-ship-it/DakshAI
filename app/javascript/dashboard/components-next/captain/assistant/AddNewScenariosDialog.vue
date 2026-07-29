<script setup>
import { computed, reactive } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useVuelidate } from '@vuelidate/core';
import { vOnClickOutside } from '@vueuse/components';
import { required, minLength } from '@vuelidate/validators';

import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';

const emit = defineEmits(['add']);

const { t } = useI18n();

const [showPopover, togglePopover] = useToggle();

const state = reactive({
  id: '',
  title: '',
  description: '',
  instruction: '',
});

const rules = {
  title: { required, minLength: minLength(1) },
  description: { required },
  instruction: { required },
};

const v$ = useVuelidate(rules, state);

const titleError = computed(() =>
  v$.value.title.$error
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.ERROR')
    : ''
);

const descriptionError = computed(() =>
  v$.value.description.$error
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.DESCRIPTION.ERROR')
    : ''
);

const instructionError = computed(() =>
  v$.value.instruction.$error
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.INSTRUCTION.ERROR')
    : ''
);

const resetState = () => {
  Object.assign(state, {
    id: '',
    title: '',
    description: '',
    instruction: '',
  });
};

const onClickAdd = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  await emit('add', state);
  resetState();
  togglePopover(false);
};

const onClickCancel = () => {
  togglePopover(false);
};
</script>

<template>
  <div
    v-on-click-outside="() => togglePopover(false)"
    class="relative inline-flex"
  >
    <RelayButton
      size="sm"
      class="flex-shrink-0"
      @click="togglePopover(!showPopover)"
    >
      <span class="i-lucide-plus size-4" />
      {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.CREATE') }}
    </RelayButton>

    <div
      v-if="showPopover"
      class="absolute top-10 z-50 flex w-[31.25rem] flex-col gap-6 rounded-xl border border-n-weak bg-n-solid-2 p-6 shadow-md backdrop-blur-[100px] ltr:left-0 rtl:right-0"
    >
      <h3 class="text-base font-medium text-n-slate-12">
        {{ t(`CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.TITLE`) }}
      </h3>

      <div class="flex flex-col gap-4">
        <div class="flex flex-col gap-2">
          <RelayLabel html-for="new-scenario-title">
            {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.LABEL') }}
          </RelayLabel>
          <RelayInput
            id="new-scenario-title"
            v-model="state.title"
            :placeholder="
              t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.PLACEHOLDER')
            "
          />
          <p v-if="titleError" class="text-xs text-n-ruby-11">
            {{ titleError }}
          </p>
        </div>

        <TextArea
          v-model="state.description"
          :label="
            t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.DESCRIPTION.LABEL')
          "
          :placeholder="
            t(
              'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.DESCRIPTION.PLACEHOLDER'
            )
          "
          :message="descriptionError"
          :message-type="descriptionError ? 'error' : 'info'"
          show-character-count
        />
        <Editor
          v-model="state.instruction"
          :label="
            t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.INSTRUCTION.LABEL')
          "
          :placeholder="
            t(
              'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.INSTRUCTION.PLACEHOLDER'
            )
          "
          :message="instructionError"
          :message-type="instructionError ? 'error' : 'info'"
          :show-character-count="false"
          enable-captain-tools
        />
      </div>

      <div class="flex w-full items-center justify-between gap-3">
        <RelayButton variant="secondary" class="w-full" @click="onClickCancel">
          {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.CANCEL') }}
        </RelayButton>
        <RelayButton class="w-full" @click="onClickAdd">
          {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.CREATE') }}
        </RelayButton>
      </div>
    </div>
  </div>
</template>
