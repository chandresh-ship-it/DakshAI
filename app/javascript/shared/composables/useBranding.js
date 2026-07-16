import { useMapGetter } from 'dashboard/composables/store.js';

export function useBranding() {
  const globalConfig = useMapGetter('globalConfig/get');
  const currentAccountId = useMapGetter('getCurrentAccountId');
  const getAccount = useMapGetter('accounts/getAccount');

  /**
   * Replaces "Chatwoot" or "DakshAI" in text with the installation name or custom brand name
   * @param {string} text - The text to process
   * @returns {string} - Text with "Chatwoot" / "DakshAI" replaced by installation/brand name
   */
  const replaceInstallationName = text => {
    if (!text) return text;

    let customBrandName = '';
    if (
      getAccount?.value &&
      typeof getAccount.value === 'function' &&
      currentAccountId?.value
    ) {
      const account = getAccount.value(currentAccountId.value);
      customBrandName = account?.custom_attributes?.brand_colors?.brand_name;
    }
    const installationName =
      customBrandName || globalConfig.value?.installationName;
    if (!installationName) return text;

    return text.replace(/Chatwoot|DakshAI|Newrelay/g, installationName);
  };

  return {
    replaceInstallationName,
  };
}
