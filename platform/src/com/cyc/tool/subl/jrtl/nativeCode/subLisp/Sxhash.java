/***
 *   Copyright (c) 1995-2009 Cycorp Inc.
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 *
 *  Substantial portions of this code were developed by the Cyc project
 *  and by Cycorp Inc, whose contribution is gratefully acknowledged.
*/

package com.cyc.tool.subl.jrtl.nativeCode.subLisp;

import com.cyc.tool.subl.jrtl.nativeCode.type.core.SubLObject;
import com.cyc.tool.subl.jrtl.nativeCode.type.core.SubLObjectFactory;
import com.cyc.tool.subl.jrtl.nativeCode.type.core.SubLVector;
import com.cyc.tool.subl.jrtl.nativeCode.type.number.SubLInteger;
import com.cyc.tool.subl.jrtl.nativeCode.type.number.SubLNumberFactory;
import com.cyc.tool.subl.jrtl.nativeCode.type.symbol.SubLSymbol;
import com.cyc.tool.subl.util.SubLFile;
import com.cyc.tool.subl.util.SubLFiles;
import com.cyc.tool.subl.util.SubLTrampolineFile;

//// Internal Imports

//// External Imports

public class Sxhash extends SubLTrampolineFile {

	//// Constructors

	public static SubLFile me = new Sxhash();

	public static SubLSymbol $sxhash_method_table$ = null;

	//// Public Area

	public static SubLVector hashVector = SubLObjectFactory.makeVector(256, CommonSymbols.NIL);
	public static int MAX_STRUCT_DECLARATIONS = 2048;
	public static UnaryFunction[] structHashMeths = new UnaryFunction[Sxhash.MAX_STRUCT_DECLARATIONS];
	public static SubLInteger SXHASH_BIT_LIMIT = SubLObjectFactory.makeInteger(SubLNumberFactory.FIXNUM_BIT_SIZE);

	public static int SXHASH_BIT_LIMIT2 = Sxhash.SXHASH_BIT_LIMIT.intValue();

	public static int INITIAL_COMPOSITE_STATE = 4;
	private static int[] updateCompositeStateTable = { 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
			24, 25, 26, 27, 28, 29, 30, 31, 0, 1, 2, 3, 4, 5, 6 };

	public static int compositeUpdate(int compositeHash, int partHash, int state) {
		int updatedCompositeHash = compositeHash ^ Sxhash.sxhashRotateValue(partHash, state);
		return updatedCompositeHash;
	}

	// composite hashCode utilities

	public static SubLObject sxhash(SubLObject obj) {
		int rawHashCode = 0;
		if (obj.isStructure()) {
			UnaryFunction func = Sxhash.structHashMeths[obj.toStruct().id()];
			if (func != null)
				rawHashCode = Numbers.truncateToFixnum(func.processItem(obj).intValue());
			// SubLObject hash_method = Structures.method_func(obj, hashVector);
			// return (hash_method == NIL) ? ZERO_INTEGER :
			// Functions.funcall(hash_method, obj);
		} else
			rawHashCode = Numbers.truncateToFixnum(obj.hashCode(0));
		int hashCode = Math.abs(rawHashCode);
		return SubLNumberFactory.makeInteger(hashCode);
	}

	/**
	 * Rotate the highest HIGH-BITS number of bits of FIXNUM around to the
	 * low-bits.
	 */
	public static SubLObject sxhash_rot(SubLObject fixnum, SubLObject high_bits) {
		int result = Sxhash.sxhashRotateValue(fixnum.intValue(), high_bits.intValue());
		return SubLNumberFactory.makeInteger(result);
	}

	private static int sxhashRotateValue(int num, int highBits) {
		if (highBits >= SXHASH_BIT_LIMIT2) {
			return num;
		}
		int restBits = SXHASH_BIT_LIMIT2 - highBits - 1;
		int highFixnum = num >>> restBits;
		int restMask = (1 << restBits) - 1;
		int rest = (num & restMask) << highBits;
		int result = Numbers.truncateToFixnum(highFixnum) | rest;
		/*
		 * int lowMask = ~(-1 << restBits); int lowFixnum = num & lowMask; int
		 * lowRotated = lowFixnum << highBits; int result = highFixnum |
		 * lowRotated;
		 */
		if ((result > SubLNumberFactory.MAX_FIXNUM) || (result < SubLNumberFactory.MIN_FIXNUM)) {
			int i = 0;
		}
		return result;
	}

	public static int updateCompositeState(int compositeState) {
		return Sxhash.updateCompositeStateTable[compositeState];
	}

	//// Initializers

	/** Creates a new instance of Sxhash. */
	public Sxhash() {
	}

	public void declareFunctions() {
		SubLFiles.declareFunction(Sxhash.me, "sxhash", "SXHASH", 1, 0, false);
		SubLFiles.declareFunction(Sxhash.me, "sxhash_rot", "SXHASH-ROT", 2, 0, false);
	}

	public void initializeVariables() {
		Sxhash.$sxhash_method_table$ = SubLFiles.deflexical(Sxhash.me, "*SXHASH-METHOD-TABLE*", Sxhash.hashVector);
	}

	//// Protected Area

	//// Private Area

	public void runTopLevelForms() {
	}

	//// Internal Rep

	//// Main

}
