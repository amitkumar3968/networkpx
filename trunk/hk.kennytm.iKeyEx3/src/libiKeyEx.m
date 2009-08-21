/*
 
 libiKeyEx.m ... iKeyEx support functions.
 
 Copyright (c) 2009, KennyTM~
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, 
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 * Neither the name of the KennyTM~ nor the names of its contributors may be
 used to endorse or promote products derived from this software without
 specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

#import <UIKit/UIKit.h>
#import <UIKit/UIKit2.h>
#import "libiKeyEx.h"
#include <libkern/OSAtomic.h>

extern BOOL IKXIsiKeyExMode(NSString* modeString) {
	return [modeString hasPrefix:@"iKeyEx:"];
}
extern BOOL IKXIsInternalMode(NSString* modeString) {
	return [modeString hasPrefix:@"iKeyEx:__"];
}

static NSDictionary* _IKXConfigDictionary = nil;
static int _IKXKeyboardChooserPref = 3, _IKXConfirmWithSpacePref = 2;
extern NSDictionary* IKXConfigDictionary() {
	if (_IKXConfigDictionary == nil) {
		NSDictionary* temp_IKXConfigDictionary = [[NSDictionary alloc] initWithContentsOfFile:IKX_LIB_PATH@"/Config.plist"];
		if (!OSAtomicCompareAndSwapPtrBarrier(nil, temp_IKXConfigDictionary, (void*volatile*)&_IKXConfigDictionary))
			[temp_IKXConfigDictionary release];
	}
	return _IKXConfigDictionary;
}

extern void IKXFlushConfigDictionary() {
	if (_IKXConfigDictionary != nil) {
		NSDictionary* temp_IKXConfigDictionary = _IKXConfigDictionary;
		if (OSAtomicCompareAndSwapPtrBarrier(temp_IKXConfigDictionary, nil, (void*volatile*)&_IKXConfigDictionary)) {
			_IKXKeyboardChooserPref = 3;
			_IKXConfirmWithSpacePref = 2;
			[temp_IKXConfigDictionary release];
		}
	}
}
extern int IKXKeyboardChooserPreference() { 
	if (_IKXKeyboardChooserPref >= 3) {
		NSString* kbChooser = [IKXConfigDictionary() objectForKey:@"kbChooser"];
		_IKXKeyboardChooserPref = kbChooser ? [kbChooser integerValue] : 1;
	}
	return _IKXKeyboardChooserPref;
}
extern BOOL IKXConfirmWithSpacePreference() {
	if (_IKXConfirmWithSpacePref >= 2) {
		NSNumber* confWithSpace = [IKXConfigDictionary() objectForKey:@"confirmWithSpace"];
		_IKXConfirmWithSpacePref = confWithSpace ? [confWithSpace boolValue] : 1;
	}
	return _IKXConfirmWithSpacePref;
}

//------------------------------------------------------------------------------

extern NSString* IKXLayoutReference(NSString* modeString) {
	if ([modeString isEqualToString:@"iKeyEx:__KeyboardChooser"])
		return @"__KeyboardChooser";
	else
		return [[[IKXConfigDictionary() objectForKey:@"modes"] objectForKey:modeString] objectForKey:@"layout"];
}

extern NSString* IKXInputManagerReference(NSString* modeString) {
	if ([modeString isEqualToString:@"iKeyEx:__KeyboardChooser"])
		return @"=en_US";
	else
		return [[[IKXConfigDictionary() objectForKey:@"modes"] objectForKey:modeString] objectForKey:@"manager"];
}

extern NSBundle* IKXLayoutBundle(NSString* layoutReference) {
	return [NSBundle bundleWithPath:[NSString stringWithFormat:IKX_LIB_PATH@"/Keyboards/%@.keyboard", layoutReference]];
}

extern NSBundle* IKXInputManagerBundle(NSString* imeReference) {
	return [NSBundle bundleWithPath:[NSString stringWithFormat:IKX_LIB_PATH@"/InputManagers/%@.ime", imeReference]];
}

//------------------------------------------------------------------------------

extern void IKXPlaySound() {
	[UIHardware _playSystemSound:0x450];
}

extern NSString* IKXNameOfMode(NSString* modeString) {
	if (IKXIsiKeyExMode(modeString))
		return [[[IKXConfigDictionary() objectForKey:@"modes"] objectForKey:modeString] objectForKey:@"name"];
	else {
		if ([modeString isEqualToString:@"emoji"])
			return @"Emoji";
		else if ([modeString isEqualToString:@"intl"])
			return @"QWERTY";
		else {
			NSLocale* curLocale = [NSLocale currentLocale];
			NSRange locRange = [modeString rangeOfString:@"-"];
			if (locRange.location == NSNotFound) {
				return [curLocale displayNameForKey:NSLocaleIdentifier value:modeString] ?: modeString;
			} else {
				NSString* localeStr = [curLocale displayNameForKey:NSLocaleIdentifier value:[modeString substringToIndex:locRange.location]];
				if ([modeString hasPrefix:@"zh"]) {
					NSUInteger firstOpen = [localeStr rangeOfString:@"("].location;
					if (firstOpen != NSNotFound)
						localeStr = [localeStr substringWithRange:NSMakeRange(firstOpen+1, [localeStr length]-2-firstOpen)];
				}
				NSString* type = [@"UI" stringByAppendingString:[modeString substringFromIndex:locRange.location]];
				return [NSString stringWithFormat:@"%@ (%@)", localeStr, UIKeyboardLocalizedString(type, modeString, nil)];
			}
		}
		
	}
}
