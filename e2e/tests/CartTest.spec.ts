import {test, expect} from '../BaseTest';

test('Product detail test scenario',
    async ({
               ShopCustomer,
               StorefrontProductDetail,
               ProductData,
               AddProductToCart
           }) => {

        await ShopCustomer.goesTo(StorefrontProductDetail.url(ProductData));
        await ShopCustomer.attemptsTo(AddProductToCart(ProductData));
        await ShopCustomer.expects(StorefrontProductDetail.offCanvasSummaryTotalPrice).toHaveText('€10.00*');
    });
