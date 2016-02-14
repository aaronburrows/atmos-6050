# General code conventions

In many ways programing is like writing a journal article. It needs to follow a logical order and needs to follow some general guidelines so that others can pick up your code and be able to follow along and understand your calculations. What good is your solution if others can use it or it can't be peer reviewed?

This is not an exhaustive list. Many of these standards come from industry guidance and governmental programming guidelines (mainly NASA, NOAA and the NWS). Much the formatting and variable declarations are rooted in classical programming and Fortran interoperability.


## Comments & Commented Out Code:

* All comments are denoted line by line with the comment indicator starting at the same column as the code statement.

```c
int functionName(int n)
{
    /* Define local constants */
    double const PI = 4.0 * atan(1.0);     /* Define PI */
    double const RAD_WGS84 = 6378137.0;    /* Radius of Earth, WGS84 Std, [m] */

    /* Raise the parcel from the surface to TOA */
    for (int i = 0; i < n; i++) {

        /* Comment about this block */
        ... codes goes here ...
    }
}
```

* Block comments indicate code that has been hidden from the compiler, although a single line of code will be commented out at the start of the statement whichever col that is.  An example of this is in the second segment of code in the following example.

```c
    /* Raise the parcel from the surface to TOA */
    for (int i = 0; i < n; i++) {
        ... codes goes here ...
    }


    /* Raise the parcel from the surface to TOA */
    /*
    for (int i = 0; i < n; i++) {
        ... codes goes here ...
    }
    */
```

* A short description may follow a line of code, as long as: (1) minimum of 3 spaces from the code terminator, (2) the comment text begins 1 space from the comment indicator, (3) if multiple comments are used then align them for easier reading.

```c
    result = function(x, n);  /* Comment about this function */
```

```c
    double const PI        = 4.0 * atan(1.0);   /* Define PI */
    double const RAD_WGS84 = 6378137.0;         /* Rad Earth, WGS84 Std, [m] */
```

* Sub-routine & function headers should have a description and cite references (if needed).

```c
/*******************************************************************************
 *                                                                             *
 *  Function: CollectData                                                      *
 *  Purpose:  Collects data from sensors                                       *
 *  Returns:  int, [0] Pass, [1] Error                                         *
 *                                                                             *
 *  - Arguments                                                                *
 *    Argument     Type   I/O     Description                                  *
 *    ------------------------------------------------------------------------ *
 *    None.                                                                    *
 *                                                                             *
 *  - Local variables                                                          *
 *    Name          Type    Default   Description                              *
 *    ------------------------------------------------------------------------ *
 *    DP2            F      -99999    Dewpoint from SHT10_2, Derived           *
 *    P              F      -99999    Pressure from on board BMP180            *
 *    P0             F      -99999    SLP from BMP180                          *
 *    bmp_flg        C      null      BMP180 working status:                   *
 *                                    --> 0:Fail, 1:Pass                       *
 *    data_csv       S      null      CSV test string to store                 *
 *    data_file      Obj    SD I/O    File I/O object for SD Card              *
 *    now            Obj    RTC       DateTime object from RTC                 *
 *                                                                             *
 *  - Notes                                                                    *
 *    Some of the data collection variables do not follow standard             *
 *    ISO/ANSI/NASA compliance, this is to keep their atmospheric science      *   
 *    and mathematical meanings consistent.                                    *
 ******************************************************************************/
 ```

* Section headers are denoted with a comment title.

```c
    /*
     * Begin data retrievals.
     */
```

## Indentation & Spacing:

* Maximum length of a line of code is 80 characters, with the first col being 1.

* *Absolutely NO tabs are used*. All indentation and spacing uses spaces only. This ensures consistency in all text editors and compilers.

 All code and user comments begin at the appropriate indentation level for the segment. Debugging code may be placed starting at col 1. This let's other programmers know if the code is for debugging or testing purposes.


## Control Structures & Blocks:

* Only rigorous logic structures are to be used. CASE & SELECT statements should not be used.

* While nested IF/THEN logic is ok to use, if a statement can be simplified using AND/OR operators then that would be recommended.

* Structured programing and reusable code techniques should be used within reason to aid in optimization.

* names of routines & sub-routines should indicated the verb of the function then the name.
   Example: get_temperature(), isPrime(), findFactors()

* All logic statements & control blocks will use braces.
* The Kernighan and Ritchie bracing style is used.

```c
    if (AA > BB) {
       DO SOMETHING
    } else {
       DO SOMETHING ELSE
    }
```

* The end of a function/sub-routine is noted by a comment inline with the closing bracket/keyword.
