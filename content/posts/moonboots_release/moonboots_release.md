+++
title = "Moonboots 1.0"
date = "2025-02-15T18:55:56+01:00"
#dateFormat = "2006-01-02" # This value can be configured for per-post date formatting
author = "ma111e"
cover = ""
tags = ["moonboots", "tool", "release", "shellcode", "injection"]
keywords = ["", ""]
description = ""
showFullContent = false
readingTime = true
hideComments = false
+++

{{< image src="/blog/posts/moonboots_release/images/header.png" alt="Moonboots header image showing a screenshot of the tool running with very badly drawn moonboots and a 'Moonboots 1.0' text badly drawn over it" position="center" style="border-radius: 8px;" >}}

## TL;DR
I'm releasing a tool I use while reversing: Moonboots—a shellcode injector with features like encoding–agnostic hex input, automatic cleanup, clipboard sourcing, shellcode idling, managed use support, and a plugin framework to easily implement new techniques.

The release is available on [GitHub](https://github.com/ma111e/moonboots), and the full documentation on the [repository's Pages](https://ma111e.github.io/moonboots/#/). 

## Introduction

Shellcode injection has long been a part of the malware authors' cookbooks. Whether used as part of complex loading chains or to evade countermeasures, this technique is likely to remain relevant for a long time.

Digging out shellcode during malware analysis is quite common. However, shellcode is often just a sequence of instructions, with no means of being loaded and run by the OS—which can be a problem for standard procedure like dynamic analysis.

There are many ways to run and analyze such piece of code independently. Still, I prefer to stay as close as possible to the malware’s actual operational context. I often choose either to patch the malware or to use debugger tricks to get a hold on the shellcode execution—but there have been many instances where a flexible loader that I know well could have saved me a lot of time.

Many loaders and injectors are available online, yet I have never found one I felt completely comfortable using. Even worse, some didn’t work as I expected, wasting my time as I reviewed the code to determine whether my hypothesis was wrong or if I had made a mistake while using the tool.

Plus, I love to learn malware techniques by implementing them myself. And I love to write tools.

This is how I came to build Moonboots, the shellcode injector I'm releasing here. I wrote this program a few years ago, when Golang was rapidly gaining popularity among malware authors. I chose to focus on implementing the injection techniques I encountered using pure Go, both to better understand the language’s constraints and to have a lab environment that was easy to use for research.

## Moonboots[^1]
At its core, this program is a shellcode injector: it takes shellcode as input and uses a specific technique to inject it into a target. That's all. 

However, I built it with two additional requirements in mind: 
+ It must be as easy to use as I can think of
+ It must be extensible in a way that prevents the implementation of novel techniques from becoming a daunting time sink during research

### Input
One of the first pain points I wanted to address was the inconsistency in shellcode formats across different sources. Converting `\xFF` to `0xFF` or `FF`, normalizing spaces and case, removing quotes and the likes has always felt like such a petty discomfort that I needed to handle it automatically. Nobody should have to waste time on that. 

As such, Moonboots will guess the input format automatically[^2], whether it's hex or raw bytes. It's also able to clean the input a bit, so you can actually copy/paste shellcode right from the output of a `xxd -p` command or from a C source code and feed it to it without any remorse.

```c
char shellcode[] =
"\x31\xc0\x31\xdb\x31\xc9\x31\xd2"
"\x51\x68\x6c\x6c\x20\x20\x68\x33"
"\x32\x2e\x64\x68\x75\x73\x65\x72"
"\x89\xe1\xbb\x7b\x1d\x80\x7c\x51" // 0x7c801d7b ; LoadLibraryA(user32.dll)
"\xff\xd3\xb9\x5e\x67\x30\xef\x81"
"\xc1\x11\x11\x11\x11\x51\x68\x61"
"\x67\x65\x42\x68\x4d\x65\x73\x73"
"\x89\xe1\x51\x50\xbb\x40\xae\x80" // 0x7c80ae40 ; GetProcAddress(user32.dll, MessageBoxA)
"\x7c\xff\xd3\x89\xe1\x31\xd2\x52"
"\x51\x51\x52\xff\xd0\x31\xc0\x50"
"\xb8\x12\xcb\x81\x7c\xff\xd0";    // 0x7c81cb12 ; ExitProcess(0)
```
> *Yes, you can use this as input without any trouble*

I also added a flag to fetch the input from the clipboard because I'm lazy. And it's kinda cool. But also a bit tricky. Is the shellcode that'll run the one that I copied or the one before ? Let's find out ⌐■\_■. Maybe use this one with caution. Finding the right shellcode variation is so much easier tho. ¯\\\_(ツ)\_/¯

Note that a `--demo` flag is available for testing and will inject a hardcoded `calc.exe` shellcode in its own memory. The actual shellcode is shown in the program's help. Additionally, the `moonboots/demo/{arch}` folder contains examples of the supported file formats.

Some say that base64 is also supported, although it needs to be explicitly specified via the CLI.

All the details about the detection and cleanup are available in the [Quickstart](https://ma111e.github.io/moonboots/#/user_guide/quickstart) section of the documentation. 

### Privileges
Some shellcode techniques have strict requirements, such as being executed from a high-integrity process or with specific privileges. Moonboots can enable any required privileges and restart itself with high integrity if necessary. Note that self-enabling privileges will always trigger an auto-elevation.

### Managed use
Shellcode injection is just one step in malware analysis. Most of the time, we use multiple tools to examine different aspects of the malware, often managed by an orchestration program that bridges tools together and passes data between them.

For such cases, Moonboots can function as a custom shellcode loader by using a special flag that specifies the name of a named pipe. The process running the shellcode will then be sent back upon creation.

See the [Managed Use](https://ma111e.github.io/moonboots/#/developers/managed_use) section of the documentation for full details and boilerplate code.

### Quality of life
For those who might not be aware, `EB FE` is love, `EB FE` is life. This instruction means "(EB) jump to the relative offset (FE) -1"—*aka* an infinite loop. 

Any Windows process running these two bytes will not advance to any further instruction, effectively halting the execution of the program without using any debugger feature. This is typically used to give us the time to attach a debugger after anti-debugging checks have passed.

Regarding shellcode injection however, it has another valuable use: pausing execution immediately after injection. This is particularly useful when injecting shellcode into a remote process or through complex methods that are difficult to track with a debugger.

To this end, Moonboots includes a flag that will prepend these 2 bytes to the shellcode before injecting it.

See the [Idle](https://ma111e.github.io/moonboots/#/developers/managed_use) section of the documentation for more details.

## Conclusion
The tool is available on [GitHub](https://github.com/ma111e/moonboots), and the full documentation on the [repository's Pages](https://ma111e.github.io/moonboots/#/). 

Issues and pull requests are welcomed.


[^1]: Why "Moonboots" ? Because there had to be a name—and I love moonboots. Malware would 100% look cooler in moonboots.
[^2]: Note that custom shellcode crafted through deep madness (e.g. https://www.usenix.org/system/files/woot20-paper-patel_0.pdf) might defeat the auto-detection feature. In this case, the encoding should be manually specified via the CLI.