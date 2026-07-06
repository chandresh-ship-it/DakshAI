<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import PhoneNumberInput from 'dashboard/components-next/phonenumberinput/PhoneNumberInput.vue';
import timezones from 'dashboard/routes/dashboard/settings/inbox/helpers/timezones.json';

const emit = defineEmits(['create']);

const { t } = useI18n();

const isOpen = ref(false);
const isSaving = ref(false);

const firstName = ref('');
const lastName = ref('');
const emails = ref([{ value: '', primary: true }]);
const phoneNumbers = ref([{ value: '', primary: true }]);
const contactType = ref('lead');
const selectedTimezone = ref('Etc/UTC');

const dndAll = ref(false);
const dndEmail = ref(false);
const dndSms = ref(false);
const dndCalls = ref(false);
const dndInbound = ref(false);

const timezoneOptions = computed(() => {
  return Object.entries(timezones).map(([label, value]) => ({
    label,
    value,
  }));
});

const contactTypeOptions = [
  { label: 'Visitor', value: 'visitor' },
  { label: 'Lead', value: 'lead' },
  { label: 'Customer', value: 'customer' },
];

const resetForm = () => {
  firstName.value = '';
  lastName.value = '';
  emails.value = [{ value: '', primary: true }];
  phoneNumbers.value = [{ value: '', primary: true }];
  contactType.value = 'lead';
  selectedTimezone.value = 'Etc/UTC';
  dndAll.value = false;
  dndEmail.value = false;
  dndSms.value = false;
  dndCalls.value = false;
  dndInbound.value = false;
};

const open = () => {
  isOpen.value = true;
  resetForm();
};

const close = () => {
  isOpen.value = false;
};

const addEmail = () => {
  emails.value.push({ value: '', primary: false });
};

const removeEmail = index => {
  const wasPrimary = emails.value[index].primary;
  emails.value.splice(index, 1);
  if (wasPrimary && emails.value.length) {
    emails.value[0].primary = true;
  }
};

const setPrimaryEmail = index => {
  emails.value.forEach((email, i) => {
    email.primary = i === index;
  });
};

const addPhone = () => {
  phoneNumbers.value.push({ value: '', primary: false });
};

const removePhone = index => {
  const wasPrimary = phoneNumbers.value[index].primary;
  phoneNumbers.value.splice(index, 1);
  if (wasPrimary && phoneNumbers.value.length) {
    phoneNumbers.value[0].primary = true;
  }
};

const setPrimaryPhone = index => {
  phoneNumbers.value.forEach((phone, i) => {
    phone.primary = i === index;
  });
};

const handleSave = async (addAnother = false) => {
  isSaving.value = true;

  const primaryEmail = emails.value.find(e => e.primary)?.value || '';
  const primaryPhone = phoneNumbers.value.find(p => p.primary)?.value || '';

  const payload = {
    name: `${firstName.value} ${lastName.value}`.trim(),
    email: primaryEmail,
    phone_number: primaryPhone,
    contact_type: contactType.value,
    additional_attributes: {
      emails: emails.value.filter(e => e.value.trim()).map(e => e.value),
      phone_numbers: phoneNumbers.value
        .filter(p => p.value.trim())
        .map(p => p.value),
      timezone: selectedTimezone.value,
      dnd_settings: {
        dnd_all: dndAll.value,
        email: dndAll.value || dndEmail.value,
        sms: dndAll.value || dndSms.value,
        calls: dndAll.value || dndCalls.value,
        inbound: dndAll.value || dndInbound.value,
      },
    },
  };

  emit('create', payload);

  isSaving.value = false;
  if (addAnother) {
    resetForm();
  } else {
    close();
  }
};

defineExpose({ open, close });
</script>

<template>
  <div
    v-show="isOpen"
    class="fixed inset-0 z-[100] flex justify-end bg-n-alpha-black2 backdrop-blur-sm"
    @click.self="close"
  >
    <div
      class="w-full max-w-lg h-full bg-n-surface-1 shadow-2xl flex flex-col transition-transform duration-300 transform translate-x-0"
    >
      <!-- Header -->
      <div
        class="p-6 border-b border-n-slate-4 flex items-center justify-between"
      >
        <h2 class="text-lg font-semibold text-n-slate-12">
          {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.TITLE') }}
        </h2>
        <Button
          icon="i-lucide-x"
          variant="ghost"
          color="slate"
          size="sm"
          @click="close"
        />
      </div>

      <!-- Form Content -->
      <div class="flex-1 overflow-y-auto p-6 space-y-6">
        <!-- Name fields -->
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
              {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.FIRST_NAME') }}
            </label>
            <Input
              v-model="firstName"
              placeholder="Enter First name"
              class="w-full"
            />
          </div>
          <div>
            <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
              {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.LAST_NAME') }}
            </label>
            <Input
              v-model="lastName"
              placeholder="Enter Last name"
              class="w-full"
            />
          </div>
        </div>

        <!-- Emails Section -->
        <div>
          <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
            {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.EMAIL') }}
          </label>
          <div class="space-y-3">
            <div
              v-for="(email, index) in emails"
              :key="index"
              class="flex items-center gap-3"
            >
              <input
                type="radio"
                :checked="email.primary"
                class="accent-n-brand size-4 cursor-pointer"
                @change="setPrimaryEmail(index)"
              />
              <Input
                v-model="email.value"
                type="email"
                placeholder="Please enter email address"
                class="flex-1"
              />
              <Button
                v-if="emails.length > 1"
                icon="i-lucide-trash"
                variant="ghost"
                color="slate"
                size="sm"
                class="size-8 text-n-slate-9 hover:text-n-ruby-9"
                @click="removeEmail(index)"
              />
            </div>
            <button
              class="text-xs font-semibold text-n-brand hover:underline flex items-center gap-1 cursor-pointer"
              @click="addEmail"
            >
              <span class="text-sm">+</span>
              {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.ADD_EMAIL') }}
            </button>
          </div>
        </div>

        <!-- Phones Section -->
        <div>
          <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
            {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.PHONE') }}
          </label>
          <div class="space-y-3">
            <div
              v-for="(phone, index) in phoneNumbers"
              :key="index"
              class="flex items-center gap-3"
            >
              <input
                type="radio"
                :checked="phone.primary"
                class="accent-n-brand size-4 cursor-pointer"
                @change="setPrimaryPhone(index)"
              />
              <PhoneNumberInput
                v-model="phone.value"
                placeholder="Enter phone number"
                class="flex-1"
              />
              <Button
                v-if="phoneNumbers.length > 1"
                icon="i-lucide-trash"
                variant="ghost"
                color="slate"
                size="sm"
                class="size-8 text-n-slate-9 hover:text-n-ruby-9"
                @click="removePhone(index)"
              />
            </div>
            <button
              class="text-xs font-semibold text-n-brand hover:underline flex items-center gap-1 cursor-pointer"
              @click="addPhone"
            >
              <span class="text-sm">+</span>
              {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.ADD_PHONE') }}
            </button>
          </div>
        </div>

        <!-- Contact Type -->
        <div>
          <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
            {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.CONTACT_TYPE') }}
          </label>
          <ComboBox
            v-model="contactType"
            :options="contactTypeOptions"
            placeholder="Select Contact type"
            class="w-full [&>div>button]:h-10"
          />
        </div>

        <!-- Timezone -->
        <div>
          <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
            {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.TIMEZONE') }}
          </label>
          <ComboBox
            v-model="selectedTimezone"
            :options="timezoneOptions"
            placeholder="Select Time zone"
            class="w-full [&>div>button]:h-10"
          />
        </div>

        <!-- Do Not Disturb (DND) -->
        <div class="space-y-4">
          <label class="flex items-start gap-2.5 cursor-pointer">
            <Checkbox v-model="dndAll" />
            <div class="flex flex-col">
              <span class="text-sm font-semibold text-n-slate-12">
                {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.DND_ALL') }}
              </span>
            </div>
          </label>

          <!-- Separator Line -->
          <div class="flex items-center gap-4 py-1">
            <div class="h-px bg-n-slate-4 flex-1" />
            <span
              class="text-xs font-bold text-n-slate-9 uppercase tracking-wide"
            >
              {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.OR_SEPARATOR') }}
            </span>
            <div class="h-px bg-n-slate-4 flex-1" />
          </div>

          <div class="space-y-3">
            <span
              class="block text-xs font-semibold text-n-slate-11 uppercase tracking-wider"
            >
              {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.CHANNELS') }}
            </span>
            <div class="space-y-2.5 pl-1">
              <label
                class="flex items-center gap-2.5 cursor-pointer text-sm text-n-slate-12"
                :class="{ 'opacity-50 cursor-not-allowed': dndAll }"
              >
                <Checkbox
                  :model-value="dndAll || dndEmail"
                  :disabled="dndAll"
                  @update:model-value="val => (dndEmail = val)"
                />
                <span>{{
                  t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.EMAIL_CHANNEL')
                }}</span>
              </label>
              <label
                class="flex items-center gap-2.5 cursor-pointer text-sm text-n-slate-12"
                :class="{ 'opacity-50 cursor-not-allowed': dndAll }"
              >
                <Checkbox
                  :model-value="dndAll || dndSms"
                  :disabled="dndAll"
                  @update:model-value="val => (dndSms = val)"
                />
                <span>{{
                  t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.SMS_CHANNEL')
                }}</span>
              </label>
              <label
                class="flex items-center gap-2.5 cursor-pointer text-sm text-n-slate-12"
                :class="{ 'opacity-50 cursor-not-allowed': dndAll }"
              >
                <Checkbox
                  :model-value="dndAll || dndCalls"
                  :disabled="dndAll"
                  @update:model-value="val => (dndCalls = val)"
                />
                <span>{{
                  t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.CALLS_CHANNEL')
                }}</span>
              </label>
              <label
                class="flex items-center gap-2.5 cursor-pointer text-sm text-n-slate-12"
                :class="{ 'opacity-50 cursor-not-allowed': dndAll }"
              >
                <Checkbox
                  :model-value="dndAll || dndInbound"
                  :disabled="dndAll"
                  @update:model-value="val => (dndInbound = val)"
                />
                <span class="flex items-center gap-1.5">
                  {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.INBOUND_CHANNEL') }}
                  <span class="i-lucide-info size-4 text-n-slate-9" />
                </span>
              </label>
            </div>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div
        class="p-6 border-t border-n-slate-4 bg-n-slate-2 flex items-center justify-between shrink-0"
      >
        <Button
          :label="t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.SAVE_ADD_ANOTHER')"
          variant="link"
          color="slate"
          class="hover:!no-underline text-n-brand"
          :is-loading="isSaving"
          @click="handleSave(true)"
        />
        <div class="flex items-center gap-3">
          <Button
            :label="t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.CANCEL')"
            variant="ghost"
            color="slate"
            @click="close"
          />
          <Button
            :label="t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.SAVE')"
            variant="solid"
            :is-loading="isSaving"
            @click="handleSave(false)"
          />
        </div>
      </div>
    </div>
  </div>
</template>
