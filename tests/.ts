import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Freelancer can register and get initial stats",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('freelancer-rep', 'register-freelancer', [], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        
        let getStats = chain.callReadOnlyFn(
            'freelancer-rep',
            'get-freelancer-rating',
            [types.principal(wallet1.address)],
            wallet1.address
        );
        
        getStats.result.expectOk().expectTuple()
            ['average-rating'].assertEquals(types.uint(0));
    }
});

Clarinet.test({
    name: "Client can rate a freelancer",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const client = accounts.get('wallet_1')!;
        const freelancer = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('freelancer-rep', 'register-freelancer', [], freelancer.address),
            Tx.contractCall('freelancer-rep', 'rate-freelancer', [
                types.principal(freelancer.address),
                types.uint(1),
                types.uint(5)
            ], client.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        block.receipts[1].result.expectOk().expectBool(true);
        
        let getStats = chain.callReadOnlyFn(
            'freelancer-rep',
            'get-freelancer-rating',
            [types.principal(freelancer.address)],
            freelancer.address
        );
        
        getStats.result.expectOk().expectTuple()
            ['average-rating'].assertEquals(types.uint(5));
    }
});

Clarinet.test({
    name: "Freelancer can deactivate profile",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const freelancer = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('freelancer-rep', 'register-freelancer', [], freelancer.address),
            Tx.contractCall('freelancer-rep', 'deactivate-profile', [], freelancer.address)
        ]);
        
        block.receipts.map(receipt => receipt.result.expectOk().expectBool(true));
        
        let getStats = chain.callReadOnlyFn(
            'freelancer-rep',
            'get-freelancer-rating',
            [types.principal(freelancer.address)],
            freelancer.address
        );
        
        getStats.result.expectOk().expectTuple()
            ['active'].assertEquals(false);
    }
});
