/* Coverity Scan model
 * This is a modeling file for Coverity Scan. Modeling helps to avoid false
 * positives.
 *
 * - A model file can't import any header files.  Some built-in primitives are
 *   available but not wchar_t, NULL etc.
 * - Modeling doesn't need full structs and typedefs. Rudimentary structs
 *   and similar types are sufficient.
 * - An uninitialized local variable signifies that the variable could be
 *   any value.
 *
 * The model file must be uploaded by an admin in the analysis settings of
 * https://scan.coverity.com/projects/2270
 */

/* -- Utilities -- */

#define NULL ((void*)0)
#define assert(x) if (!(x)) __coverity_panic__();
