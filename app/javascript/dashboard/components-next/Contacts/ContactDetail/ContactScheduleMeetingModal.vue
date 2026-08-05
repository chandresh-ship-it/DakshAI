<script setup>
import { reactive, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';

defineProps({
  contactName: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();

const form = reactive({
  title: '',
  date: '',
  time: '',
  notes: '',
});

const canSubmit = computed(
  () => Boolean(form.title.trim()) && Boolean(form.date)
);

const submit = () => {
  // Gap: no meetings API yet — UI shell only.
  useAlert(t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.GAP_MESSAGE'));
  emit('close');
};
</script>

<template>
  <div
    class="fixed inset-0 z-[60] flex items-center justify-center bg-n-alpha-black2 p-4 backdrop-blur-[4px]"
    @click.self="emit('close')"
  >
    <div
      class="flex max-h-[90vh] w-full max-w-lg flex-col overflow-hidden rounded-xl border border-border bg-card shadow-2xl animate-in fade-in zoom-in-95 duration-200"
    >
      <div
        class="flex shrink-0 items-center justify-between border-b border-border/40 px-8 pb-0 pt-8"
      >
        <div>
          <h2 class="text-base font-semibold leading-6 text-foreground">
            {{ t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.TITLE') }}
          </h2>
          <p class="mt-1 text-sm text-muted-foreground">
            {{
              t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.SUBTITLE', {
                name: contactName,
              })
            }}
          </p>
        </div>
        <RelayButton
          variant="ghost"
          size="icon"
          class="size-8 rounded-full text-muted-foreground hover:text-foreground"
          @click="emit('close')"
        >
          <span class="i-lucide-x size-4" />
        </RelayButton>
      </div>

      <div class="flex-1 space-y-6 overflow-y-auto px-8 pb-8 pt-4">
        <div class="flex flex-col gap-1.5">
          <label class="text-[13.5px] font-medium text-foreground">
            {{ t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.MEETING_TITLE') }}
          </label>
          <RelayInput
            v-model="form.title"
            :placeholder="
              t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.TITLE_PLACEHOLDER')
            "
            class-name="h-10 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
          />
        </div>

        <div class="grid grid-cols-2 gap-3">
          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.DATE') }}
            </label>
            <input
              v-model="form.date"
              type="date"
              class="flex h-10 w-full rounded-md border border-border/80 bg-background px-3 text-[14px] text-foreground shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
            />
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.TIME') }}
            </label>
            <input
              v-model="form.time"
              type="time"
              class="flex h-10 w-full rounded-md border border-border/80 bg-background px-3 text-[14px] text-foreground shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
            />
          </div>
        </div>

        <div class="flex flex-col gap-1.5">
          <label class="text-[13.5px] font-medium text-foreground">
            {{ t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.NOTES') }}
          </label>
          <textarea
            v-model="form.notes"
            :placeholder="
              t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.NOTES_PLACEHOLDER')
            "
            class="min-h-[100px] w-full resize-none rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
          />
        </div>
      </div>

      <div
        class="mt-auto flex shrink-0 gap-3 border-t border-border bg-muted/10 p-6"
      >
        <RelayButton
          variant="outline"
          class="w-full text-sm font-medium"
          @click="emit('close')"
        >
          {{ t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.CANCEL') }}
        </RelayButton>
        <RelayButton
          class="w-full text-sm font-medium"
          :disabled="!canSubmit"
          @click="submit"
        >
          {{ t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.SUBMIT') }}
        </RelayButton>
      </div>
    </div>
  </div>
</template>
