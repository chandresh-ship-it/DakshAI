<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';

defineProps({
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['create']);
const { t } = useI18n();

const isOpen = ref(false);
const showErrors = ref(false);
const logoInput = ref(null);
const logoPreview = ref('');

const form = reactive({
  name: '',
  phone: '',
  email: '',
  website: '',
  address: '',
  state: '',
  city: '',
  description: '',
  owner: '',
  members: '',
});

const isFormValid = computed(() => form.name.trim() !== '');

const resetForm = () => {
  form.name = '';
  form.phone = '';
  form.email = '';
  form.website = '';
  form.address = '';
  form.state = '';
  form.city = '';
  form.description = '';
  form.owner = '';
  form.members = '';
  logoPreview.value = '';
  showErrors.value = false;
};

const open = () => {
  isOpen.value = true;
};

const close = () => {
  isOpen.value = false;
  resetForm();
};

const handleLogoUpload = event => {
  const file = event.target?.files?.[0];
  if (!file) return;
  logoPreview.value = URL.createObjectURL(file);
};

const domainFromWebsite = website => {
  if (!website?.trim()) return null;
  return website
    .replace(/(https?:\/\/)?(www\.)?/i, '')
    .split('/')[0]
    .trim();
};

const handleSubmit = () => {
  if (!isFormValid.value) {
    showErrors.value = true;
    return;
  }

  emit('create', {
    name: form.name.trim(),
    domain: domainFromWebsite(form.website),
    description: form.description.trim() || null,
    additionalAttributes: {
      phone: form.phone.trim() || undefined,
      email: form.email.trim() || undefined,
      website: form.website.trim() || undefined,
      address: form.address.trim() || undefined,
      state: form.state.trim() || undefined,
      city: form.city.trim() || undefined,
      owner: form.owner.trim() || undefined,
      members: form.members.trim() || undefined,
    },
  });
};

const onSuccess = () => {
  resetForm();
  close();
};

const dialogRef = {
  open,
  close,
};

defineExpose({ dialogRef, open, close, onSuccess });
</script>

<template>
  <Teleport to="body">
    <div
      v-if="isOpen"
      class="fixed inset-0 z-[60] flex items-center justify-center bg-background/80 p-4 backdrop-blur-sm transition-all duration-300"
      @click.self="close"
    >
      <div
        class="flex max-h-[90vh] w-full max-w-2xl animate-in fade-in zoom-in-95 flex-col overflow-hidden rounded-xl border border-border bg-card shadow-2xl duration-200"
      >
        <div
          class="flex shrink-0 items-center justify-between border-b border-border/40 p-6"
        >
          <div>
            <h2 class="text-lg font-semibold tracking-tight text-foreground">
              {{ t('COMPANIES.CREATE.TITLE') }}
            </h2>
            <p class="mt-1 text-sm text-muted-foreground">
              {{ t('COMPANIES.CREATE.SUBTITLE') }}
            </p>
          </div>
          <RelayButton
            variant="ghost"
            size="icon"
            class="size-8 rounded-full text-muted-foreground hover:text-foreground"
            @click="close"
          >
            <span class="i-lucide-x size-4" />
          </RelayButton>
        </div>

        <div
          class="hide-scrollbar grid flex-1 grid-cols-2 gap-x-6 gap-y-5 overflow-y-auto p-6"
        >
          <div class="col-span-2 flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.LOGO') }}
            </label>
            <div class="mb-2 flex items-center gap-4">
              <button
                type="button"
                class="flex size-16 shrink-0 cursor-pointer items-center justify-center overflow-hidden rounded-xl border border-dashed border-border/80 bg-muted/30 transition-colors hover:bg-muted/50"
                @click="logoInput?.click()"
              >
                <img
                  v-if="logoPreview"
                  :src="logoPreview"
                  alt=""
                  class="size-full object-cover"
                />
                <span
                  v-else
                  class="i-lucide-upload size-5 text-muted-foreground/70"
                />
              </button>
              <div class="flex flex-col gap-1.5">
                <RelayButton
                  variant="outline"
                  size="sm"
                  class="h-8 w-fit text-xs"
                  @click="logoInput?.click()"
                >
                  {{ t('COMPANIES.CREATE.ACTIONS.UPLOAD_LOGO') }}
                </RelayButton>
                <span class="text-[11px] text-muted-foreground">
                  {{ t('COMPANIES.CREATE.LOGO_HINT') }}
                </span>
                <input
                  ref="logoInput"
                  type="file"
                  accept="image/*"
                  class="hidden"
                  @change="handleLogoUpload"
                />
              </div>
            </div>
          </div>

          <div class="col-span-2 flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.NAME') }}
              <span class="text-destructive">{{
                t('COMPANIES.CREATE.REQUIRED_MARK')
              }}</span>
            </label>
            <RelayInput
              v-model="form.name"
              :placeholder="t('COMPANIES.CREATE.FIELDS.NAME_PLACEHOLDER')"
              class-name="h-10 w-full rounded-md border-border/80 bg-background text-[14px] shadow-sm"
              :disabled="isLoading"
            />
            <p
              v-if="showErrors && !form.name.trim()"
              class="mt-1 text-[12px] text-destructive"
            >
              {{ t('COMPANIES.CREATE.NAME_REQUIRED') }}
            </p>
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.OWNER') }}
            </label>
            <RelayInput
              v-model="form.owner"
              :placeholder="t('COMPANIES.CREATE.FIELDS.OWNER_PLACEHOLDER')"
              class-name="h-10 w-full rounded-md border-border/80 bg-background text-[14px] shadow-sm"
              :disabled="isLoading"
            />
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.MEMBERS') }}
            </label>
            <RelayInput
              v-model="form.members"
              :placeholder="t('COMPANIES.CREATE.FIELDS.MEMBERS_PLACEHOLDER')"
              class-name="h-10 w-full rounded-md border-border/80 bg-background text-[14px] shadow-sm"
              :disabled="isLoading"
            />
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.PHONE') }}
            </label>
            <RelayInput
              v-model="form.phone"
              type="tel"
              :placeholder="t('COMPANIES.CREATE.FIELDS.PHONE_PLACEHOLDER')"
              class-name="h-10 w-full rounded-md border-border/80 bg-background text-[14px] shadow-sm"
              :disabled="isLoading"
            />
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.EMAIL') }}
            </label>
            <RelayInput
              v-model="form.email"
              type="email"
              :placeholder="t('COMPANIES.CREATE.FIELDS.EMAIL_PLACEHOLDER')"
              class-name="h-10 w-full rounded-md border-border/80 bg-background text-[14px] shadow-sm"
              :disabled="isLoading"
            />
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.WEBSITE') }}
            </label>
            <RelayInput
              v-model="form.website"
              :placeholder="t('COMPANIES.CREATE.FIELDS.WEBSITE_PLACEHOLDER')"
              class-name="h-10 w-full rounded-md border-border/80 bg-background text-[14px] shadow-sm"
              :disabled="isLoading"
            />
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.ADDRESS') }}
            </label>
            <RelayInput
              v-model="form.address"
              :placeholder="t('COMPANIES.CREATE.FIELDS.ADDRESS_PLACEHOLDER')"
              class-name="h-10 w-full rounded-md border-border/80 bg-background text-[14px] shadow-sm"
              :disabled="isLoading"
            />
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.STATE') }}
            </label>
            <RelayInput
              v-model="form.state"
              :placeholder="t('COMPANIES.CREATE.FIELDS.STATE_PLACEHOLDER')"
              class-name="h-10 w-full rounded-md border-border/80 bg-background text-[14px] shadow-sm"
              :disabled="isLoading"
            />
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.CITY') }}
            </label>
            <RelayInput
              v-model="form.city"
              :placeholder="t('COMPANIES.CREATE.FIELDS.CITY_PLACEHOLDER')"
              class-name="h-10 w-full rounded-md border-border/80 bg-background text-[14px] shadow-sm"
              :disabled="isLoading"
            />
          </div>

          <div class="col-span-2 flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.DESCRIPTION') }}
              <span class="font-normal text-muted-foreground">
                {{ t('COMPANIES.CREATE.OPTIONAL') }}
              </span>
            </label>
            <textarea
              v-model="form.description"
              :placeholder="
                t('COMPANIES.CREATE.FIELDS.DESCRIPTION_PLACEHOLDER')
              "
              :disabled="isLoading"
              class="min-h-[80px] w-full resize-y rounded-md border border-border/80 bg-background p-3 text-[14px] text-foreground shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:opacity-50"
            />
          </div>
        </div>

        <div
          class="mt-auto flex shrink-0 items-center justify-between border-t border-border bg-muted/10 p-6"
        >
          <RelayButton
            variant="ghost"
            class="text-sm font-medium"
            @click="close"
          >
            {{ t('COMPANIES.CREATE.ACTIONS.CANCEL') }}
          </RelayButton>
          <RelayButton
            class="text-sm font-medium shadow-sm"
            :disabled="!isFormValid || isLoading"
            @click="handleSubmit"
          >
            {{ t('COMPANIES.CREATE.ACTIONS.SAVE') }}
          </RelayButton>
        </div>
      </div>
    </div>
  </Teleport>
</template>
