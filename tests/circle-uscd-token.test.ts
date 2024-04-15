import { Cl } from "@stacks/transactions";
import { beforeEach, describe, expect, it } from "vitest";

const tokenContractName = "circle-usdc-token";
const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const authorizedMinter = accounts.get("wallet_1")!;
const alice = accounts.get("wallet_2")!;
const bob = accounts.get("wallet_3")!;
const finalOwner = accounts.get("wallet_4")!;

describe("USDC Token Initial State test suite", () => {
  it("ensures simnet is well initialized", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  it("ensures that the initial contract owner is the contract deployer", () => {
    let res = simnet.callReadOnlyFn(
      tokenContractName,
      "get-contract-owner",
      [],
      alice,
    ).result;
    expect(res).toBeOk(Cl.principal(deployer));
  });

  it("ensures that tokens can't be minted", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "mint!",
      [Cl.principal(alice), Cl.uint(1), Cl.none()],
      authorizedMinter,
    ).result;
    expect(res).toBeErr(Cl.uint(10000));
  });

  it("ensures that the token is paused", () => {
    let res = simnet.callReadOnlyFn(
      tokenContractName,
      "is-token-paused",
      [],
      authorizedMinter,
    ).result;
    expect(res).toBeOk(Cl.bool(true));
  });

  it("ensures that the token supply is 0", () => {
    let res = simnet.callReadOnlyFn(
      tokenContractName,
      "get-total-supply",
      [],
      authorizedMinter,
    ).result;
    expect(res).toBeOk(Cl.uint(0));
  });

  it("ensures that token's initial name is 'USDC.e (Bridged by X)'", () => {
    let res = simnet.callReadOnlyFn(
      tokenContractName,
      "get-name",
      [],
      alice,
    ).result;
    expect(res).toBeOk(Cl.stringAscii("USDC.e (Bridged by X)"));
  });

  it("ensures that token's initial symbol is 'USDC.e'", () => {
    let res = simnet.callReadOnlyFn(
      tokenContractName,
      "get-symbol",
      [],
      alice,
    ).result;
    expect(res).toBeOk(Cl.stringAscii("USDC.e"));
  });

  it("ensures that token's metadata URI is 'http://url.to/token-metadata.json'", () => {
    let res = simnet.callReadOnlyFn(
      tokenContractName,
      "get-token-uri",
      [],
      alice,
    ).result;
    expect(res).toBeOk(
      Cl.some(Cl.stringUtf8("http://url.to/token-metadata.json")),
    );
  });

  it("ensures that token's decimals is 8", () => {
    let res = simnet.callReadOnlyFn(
      tokenContractName,
      "get-decimals",
      [],
      alice,
    ).result;
    expect(res).toBeOk(Cl.uint(8));
  });
});

describe("USDC Token Contract Owner Role test suite", () => {
  let unauthorizedSenders = [alice, authorizedMinter];

  it("ensures that only owner can ban addresses", () => {
    for (let sender of unauthorizedSenders) {
      let res = simnet.callPublicFn(
        tokenContractName,
        "ban-address",
        [Cl.principal(bob)],
        sender,
      ).result;
      expect(res).toBeErr(Cl.uint(10000));
    }
  });

  it("ensures that only owner can unban addresses", () => {
    for (let sender of unauthorizedSenders) {
      let res = simnet.callPublicFn(
        tokenContractName,
        "unban-address",
        [Cl.principal(bob)],
        sender,
      ).result;
      expect(res).toBeErr(Cl.uint(10000));
    }
  });

  it("ensures that only owner can pause the token", () => {
    for (let sender of unauthorizedSenders) {
      let res = simnet.callPublicFn(
        tokenContractName,
        "pause-token",
        [],
        sender,
      ).result;
      expect(res).toBeErr(Cl.uint(10000));
    }
  });

  it("ensures that only owner can unpause the token", () => {
    for (let sender of unauthorizedSenders) {
      let res = simnet.callPublicFn(
        tokenContractName,
        "unpause-token",
        [],
        sender,
      ).result;
      expect(res).toBeErr(Cl.uint(10000));
    }
  });

  it("ensures that only owner can update token symbol", () => {
    for (let sender of unauthorizedSenders) {
      let res = simnet.callPublicFn(
        tokenContractName,
        "set-token-symbol",
        [Cl.stringAscii("USDC")],
        sender,
      ).result;
      expect(res).toBeErr(Cl.uint(10000));
    }
  });

  it("ensures that only owner can update token name", () => {
    for (let sender of unauthorizedSenders) {
      let res = simnet.callPublicFn(
        tokenContractName,
        "set-token-name",
        [Cl.stringAscii("USDC")],
        sender,
      ).result;
      expect(res).toBeErr(Cl.uint(10000));
    }
  });

  it("ensures that only owner can update token metadata", () => {
    for (let sender of unauthorizedSenders) {
      let res = simnet.callPublicFn(
        tokenContractName,
        "set-token-uri",
        [Cl.stringUtf8("http://circle.com/token-metadata.json")],
        sender,
      ).result;
      expect(res).toBeErr(Cl.uint(10000));
    }
  });

  it("ensures that only owner can update contract-owner", () => {
    for (let sender of unauthorizedSenders) {
      let res = simnet.callPublicFn(
        tokenContractName,
        "set-contract-owner",
        [Cl.principal(alice)],
        sender,
      ).result;
      expect(res).toBeErr(Cl.uint(10000));
    }
  });

  it.todo("ensures that only owner can authorize an extension", () => {});

  it.todo("ensures that only owner can deprecate an extension", () => {});
});

describe("USDC Token Minter Role test suite", () => {
  beforeEach(async () => {
    // Unpause token
    let res = simnet.callPublicFn(
      tokenContractName,
      "unpause-token",
      [],
      deployer,
    ).result;
    expect(res).toBeOk(Cl.bool(true));

    // Contract owner define minting allowance
    let allocation = 100;
    res = simnet.callPublicFn(
      tokenContractName,
      "set-minter-allowance",
      [Cl.principal(authorizedMinter), Cl.uint(allocation)],
      deployer,
    ).result;
    expect(res).toBeOk(
      Cl.tuple({
        minter: Cl.principal(authorizedMinter),
        allowance: Cl.uint(allocation),
      }),
    );
  });

  it("ensures that tokens can be minted when minter is allowed to", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "mint!",
      [Cl.principal(alice), Cl.uint(1), Cl.none()],
      authorizedMinter,
    ).result;
    Cl.prettyPrint(res);
    expect(res).toBeOk(Cl.bool(true));
  });

  it("ensures that minters can not mint more than what they're allowed to", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "mint!",
      [Cl.principal(alice), Cl.uint(101), Cl.none()],
      authorizedMinter,
    ).result;
    Cl.prettyPrint(res);
    expect(res).toBeErr(Cl.uint(10001));
  });

  it("ensures that minters can not mint more than what they're allowed to (cumulated)", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "mint!",
      [Cl.principal(alice), Cl.uint(100), Cl.none()],
      authorizedMinter,
    ).result;
    Cl.prettyPrint(res);
    expect(res).toBeOk(Cl.bool(true));

    res = simnet.callPublicFn(
      tokenContractName,
      "mint!",
      [Cl.principal(bob), Cl.uint(1), Cl.none()],
      authorizedMinter,
    ).result;
    Cl.prettyPrint(res);
    expect(res).toBeErr(Cl.uint(10001));
  });

  it("ensures that minters can keep minting if their allowance is being updated", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "mint!",
      [Cl.principal(alice), Cl.uint(100), Cl.none()],
      authorizedMinter,
    ).result;
    Cl.prettyPrint(res);
    expect(res).toBeOk(Cl.bool(true));

    res = simnet.callPublicFn(
      tokenContractName,
      "mint!",
      [Cl.principal(bob), Cl.uint(1), Cl.none()],
      authorizedMinter,
    ).result;
    Cl.prettyPrint(res);
    expect(res).toBeErr(Cl.uint(10001));

    let newAllowance = 200;
    res = simnet.callPublicFn(
      tokenContractName,
      "set-minter-allowance",
      [Cl.principal(authorizedMinter), Cl.uint(newAllowance)],
      deployer,
    ).result;
    expect(res).toBeOk(
      Cl.tuple({
        minter: Cl.principal(authorizedMinter),
        allowance: Cl.uint(newAllowance),
      }),
    );

    res = simnet.callPublicFn(
      tokenContractName,
      "mint!",
      [Cl.principal(bob), Cl.uint(1), Cl.none()],
      authorizedMinter,
    ).result;
    Cl.prettyPrint(res);
    expect(res).toBeOk(Cl.bool(true));
  });
});

describe("USDC Token Transfers test suite", () => {
  beforeEach(async () => {
    // Unpause token
    let res = simnet.callPublicFn(
      tokenContractName,
      "unpause-token",
      [],
      deployer,
    ).result;
    expect(res).toBeOk(Cl.bool(true));

    // Contract owner define minting allowance
    let allocation = 100;
    res = simnet.callPublicFn(
      tokenContractName,
      "set-minter-allowance",
      [Cl.principal(authorizedMinter), Cl.uint(allocation)],
      deployer,
    ).result;
    expect(res).toBeOk(
      Cl.tuple({
        minter: Cl.principal(authorizedMinter),
        allowance: Cl.uint(allocation),
      }),
    );

    // Minting 100 tokens for Alice
    res = simnet.callPublicFn(
      tokenContractName,
      "mint!",
      [Cl.principal(alice), Cl.uint(allocation), Cl.none()],
      authorizedMinter,
    ).result;
    expect(res).toBeOk(Cl.bool(true));
  });

  it("ensures that Alice, owning 100 tokens, can transfer 50 to Bob", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "transfer",
      [Cl.uint(50), Cl.principal(alice), Cl.principal(bob), Cl.none()],
      alice,
    ).result;
    expect(res).toBeOk(Cl.bool(true));
  });

  it("ensures that Alice's balance is correctly updated when Alice transfers 60 tokens to Bob", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "transfer",
      [Cl.uint(60), Cl.principal(alice), Cl.principal(bob), Cl.none()],
      alice,
    ).result;
    expect(res).toBeOk(Cl.bool(true));

    res = simnet.callReadOnlyFn(
      tokenContractName,
      "get-balance",
      [Cl.principal(alice)],
      alice,
    ).result;
    expect(res).toBeOk(Cl.uint(40));
  });

  it("ensures that Bob's balance is correctly updated when Alice transfers 60 tokens to Bob", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "transfer",
      [Cl.uint(60), Cl.principal(alice), Cl.principal(bob), Cl.none()],
      alice,
    ).result;
    expect(res).toBeOk(Cl.bool(true));

    res = simnet.callReadOnlyFn(
      tokenContractName,
      "get-balance",
      [Cl.principal(bob)],
      alice,
    ).result;
    expect(res).toBeOk(Cl.uint(60));
  });

  it("ensures that Alice's balance is correctly updated when she transfers 50 tokens to Bob", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "transfer",
      [Cl.uint(50), Cl.principal(alice), Cl.principal(bob), Cl.none()],
      alice,
    ).result;
    expect(res).toBeOk(Cl.bool(true));
  });

  it("ensures that Alice, owning 100 tokens, can transfer 100 to Bob", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "transfer",
      [Cl.uint(100), Cl.principal(alice), Cl.principal(bob), Cl.none()],
      alice,
    ).result;
    expect(res).toBeOk(Cl.bool(true));
  });

  it("ensures that Alice, owning 100 tokens, can not transfer 0 to Bob", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "transfer",
      [Cl.uint(0), Cl.principal(alice), Cl.principal(bob), Cl.none()],
      alice,
    ).result;
    expect(res).toBeErr(Cl.uint(10003));
  });

  it("ensures that Alice, owning 100 tokens, can not transfer 101 to Bob", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "transfer",
      [Cl.uint(101), Cl.principal(alice), Cl.principal(bob), Cl.none()],
      alice,
    ).result;
    expect(res).toBeErr(Cl.uint(1));
  });

  it("ensures that Alice can't perform transfers when the token is paused", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "transfer",
      [Cl.uint(101), Cl.principal(alice), Cl.principal(bob), Cl.none()],
      alice,
    ).result;
    expect(res).toBeErr(Cl.uint(1));
  });

  it("ensures that Alice, owning 100 tokens, can't transfer tokens to Bob if Bob was banned by Contract owner", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "ban-address",
      [Cl.principal(bob)],
      deployer,
    ).result;
    expect(res).toBeOk(Cl.principal(bob));

    res = simnet.callPublicFn(
      tokenContractName,
      "transfer",
      [Cl.uint(50), Cl.principal(alice), Cl.principal(bob), Cl.none()],
      alice,
    ).result;
    expect(res).toBeErr(Cl.uint(10000));
  });

  it("ensures that Alice, owning 100 tokens, can't transfer tokens to Bob if Alice was banned by Contract owner", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "ban-address",
      [Cl.principal(alice)],
      deployer,
    ).result;
    expect(res).toBeOk(Cl.principal(alice));

    res = simnet.callPublicFn(
      tokenContractName,
      "transfer",
      [Cl.uint(50), Cl.principal(alice), Cl.principal(bob), Cl.none()],
      alice,
    ).result;
    expect(res).toBeErr(Cl.uint(10000));
  });

  it("ensures that Alice, owning 100 tokens, can transfer tokens to Bob if Bob is unbanned by Contract owner", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "ban-address",
      [Cl.principal(bob)],
      deployer,
    ).result;
    expect(res).toBeOk(Cl.principal(bob));

    res = simnet.callPublicFn(
      tokenContractName,
      "transfer",
      [Cl.uint(50), Cl.principal(alice), Cl.principal(bob), Cl.none()],
      alice,
    ).result;
    expect(res).toBeErr(Cl.uint(10000));

    res = simnet.callPublicFn(
      tokenContractName,
      "unban-address",
      [Cl.principal(bob)],
      deployer,
    ).result;
    expect(res).toBeOk(Cl.principal(bob));

    res = simnet.callPublicFn(
      tokenContractName,
      "transfer",
      [Cl.uint(50), Cl.principal(alice), Cl.principal(bob), Cl.none()],
      alice,
    ).result;
    expect(res).toBeOk(Cl.bool(true));
  });

  it("ensures that Alice, owning 100 tokens, can't transfer tokens to Bob if the token is paused", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "pause-token",
      [],
      deployer,
    ).result;
    expect(res).toBeOk(Cl.bool(true));

    res = simnet.callPublicFn(
      tokenContractName,
      "transfer",
      [Cl.uint(50), Cl.principal(alice), Cl.principal(bob), Cl.none()],
      alice,
    ).result;
    expect(res).toBeErr(Cl.uint(10004));
  });

  it("ensures that Bob can not send tokens on behalf of Alice", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "transfer",
      [Cl.uint(50), Cl.principal(alice), Cl.principal(bob), Cl.none()],
      bob,
    ).result;
    expect(res).toBeErr(Cl.uint(10000));
  });
});

it.todo(
  "ensures that a banned address can not receive freshly minted tokens",
  () => {},
);

describe("USDC Token upgrade token test suite", () => {
  beforeEach(async () => {
    // Unpause token
    let res = simnet.callPublicFn(
      tokenContractName,
      "unpause-token",
      [],
      deployer,
    ).result;
    expect(res).toBeOk(Cl.bool(true));

    // Contract owner define minting allowance
    let allocation = 100;
    res = simnet.callPublicFn(
      tokenContractName,
      "set-minter-allowance",
      [Cl.principal(authorizedMinter), Cl.uint(allocation)],
      deployer,
    ).result;
    expect(res).toBeOk(
      Cl.tuple({
        minter: Cl.principal(authorizedMinter),
        allowance: Cl.uint(allocation),
      }),
    );

    // Contract owner define minting allowance
    res = simnet.callPublicFn(
      tokenContractName,
      "set-minter-allowance",
      [Cl.principal(authorizedMinter), Cl.uint(allocation)],
      deployer,
    ).result;
    expect(res).toBeOk(
      Cl.tuple({
        minter: Cl.principal(authorizedMinter),
        allowance: Cl.uint(allocation),
      }),
    );

    // Transfer ownership to finalOwner
    res = simnet.callPublicFn(
      tokenContractName,
      "set-contract-owner",
      [Cl.principal(finalOwner)],
      deployer,
    ).result;
    expect(res).toBeOk(Cl.bool(true));
  });

  it("ensures that new owner can update token symbol", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "set-token-symbol",
      [Cl.stringAscii("USDC")],
      finalOwner,
    ).result;
    expect(res).toBeOk(Cl.bool(true));

    res = simnet.callReadOnlyFn(
      tokenContractName,
      "get-symbol",
      [],
      alice,
    ).result;
    expect(res).toBeOk(Cl.stringAscii("USDC"));
  });

  it("ensures that new owner can update token name", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "set-token-name",
      [Cl.stringAscii("USDC")],
      finalOwner,
    ).result;
    expect(res).toBeOk(Cl.bool(true));

    res = simnet.callReadOnlyFn(
      tokenContractName,
      "get-name",
      [],
      alice,
    ).result;
    expect(res).toBeOk(Cl.stringAscii("USDC"));
  });

  it("ensures that new owner can update token metadata", () => {
    let res = simnet.callPublicFn(
      tokenContractName,
      "set-token-uri",
      [Cl.stringUtf8("http://circle.com/token-metadata.json")],
      finalOwner,
    ).result;
    expect(res).toBeOk(Cl.bool(true));

    res = simnet.callReadOnlyFn(
      tokenContractName,
      "get-token-uri",
      [],
      alice,
    ).result;
    expect(res).toBeOk(
      Cl.some(Cl.stringUtf8("http://circle.com/token-metadata.json")),
    );
  });
});
