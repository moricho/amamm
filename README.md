# Auction-Managed AMM (am-AMM)

## Overview

This project implements an Auction-Managed Automated Market Maker (am-AMM) using Uniswap v4 hooks. The am-AMM aims to address two key challenges in AMM design:

1. Reducing losses from informed orderflow
2. Maximizing revenue from uninformed orderflow

## Key Components

### AuctionManagedAMMHook

This contract implements the Uniswap v4 hook interface to provide the core functionality of the am-AMM:

- Allows fee-free trades for the current pool manager
- Implements dynamic fee calculation
- Collects and distributes fees

### AuctionManager

This contract manages the auction for the pool manager position:

- Handles bidding process
- Determines the current pool manager

## Features

- On-chain auction for pool manager rights
- Dynamic fee setting by the pool manager
- Fee-free trades for the pool manager, enabling efficient arbitrage
- Fee collection and distribution to liquidity providers
