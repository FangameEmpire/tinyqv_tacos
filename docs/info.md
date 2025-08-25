<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

The peripheral index is the number TinyQV will use to select your peripheral.  You will pick a free
slot when raising the pull request against the main TinyQV repository, and can fill this in then.  You
also need to set this value as the PERIPHERAL_NUM in your test script.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

# Thompson's Accelerator for Calculating Orbital Spacewar

Author: Nicklaus Thompson

Peripheral index: nn

## What it does

TBD, it calcultes trig and geometry.

## Register map

Document the registers that are used to interact with your peripheral

| Address | Name  | Access | Description                                                         |
|---------|-------|--------|---------------------------------------------------------------------|
| 0x00    | DATA  | R/W    | A word of data                                                      |

## How to test

TBD. It's a calculator, so just test it by running calculations. Exact protocol coming soon.

## External hardware

Might add direct-to-XY output, not sure yet
