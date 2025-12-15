import { authenticate } from '$lib/utils/auth';
import { getFormatter } from '$lib/utils/i18n';
import { AssetOrder, AssetVisibility, searchAssets } from '@immich/sdk';
import type { PageLoad } from './$types';

const PAGE_SIZE = 50;

export const load = (async ({ url }) => {
  await authenticate(url);
  const $t = await getFormatter();
  const result = await searchAssets({
    metadataSearchDto: {
      order: AssetOrder.Desc,
      page: 1,
      size: PAGE_SIZE,
      visibility: AssetVisibility.Timeline,
    },
  });

  return {
    assets: result.assets.items,
    meta: {
      title: $t('review_swipe_title'),
    },
  };
}) satisfies PageLoad;
