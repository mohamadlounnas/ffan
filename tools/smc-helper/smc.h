/*
 * Apple System Management Control (SMC) Tool
 * Based on smcFanControl by devnull & Hendrik Holtmann
 * GPL License
 */

#ifndef __SMC_H__
#define __SMC_H__

#include <IOKit/IOKitLib.h>

#define KERNEL_INDEX_SMC      2

#define SMC_CMD_READ_BYTES    5
#define SMC_CMD_WRITE_BYTES   6
#define SMC_CMD_READ_INDEX    8
#define SMC_CMD_READ_KEYINFO  9

#define DATATYPE_FLT          "flt "
#define DATATYPE_FPE2         "fpe2"
#define DATATYPE_SP78         "sp78"
#define DATATYPE_UINT8        "ui8 "
#define DATATYPE_UINT16       "ui16"
#define DATATYPE_UINT32       "ui32"

typedef struct {
    char                  major;
    char                  minor;
    char                  build;
    char                  reserved[1]; 
    UInt16                release;
} SMCKeyData_vers_t;

typedef struct {
    UInt16                version;
    UInt16                length;
    UInt32                cpuPLimit;
    UInt32                gpuPLimit;
    UInt32                memPLimit;
} SMCKeyData_pLimitData_t;

typedef struct {
    UInt32                dataSize;
    UInt32                dataType;
    char                  dataAttributes;
} SMCKeyData_keyInfo_t;

typedef unsigned char     SMCBytes_t[32];

typedef struct {
    UInt32                  key; 
    SMCKeyData_vers_t       vers; 
    SMCKeyData_pLimitData_t pLimitData;
    SMCKeyData_keyInfo_t    keyInfo;
    char                    result;
    char                    status;
    char                    data8;
    UInt32                  data32;
    SMCBytes_t              bytes;
} SMCKeyData_t;

typedef char              UInt32Char_t[5];

typedef struct {
    UInt32Char_t            key;
    UInt32                  dataSize;
    UInt32Char_t            dataType;
    SMCBytes_t              bytes;
} SMCVal_t;

// Function declarations
UInt32 _strtoul(char *str, int size, int base);
void _ultostr(char *str, UInt32 val);
float _strtof(unsigned char *str, int size, int e);

kern_return_t SMCOpen(io_connect_t *conn);
kern_return_t SMCClose(io_connect_t conn);
kern_return_t SMCReadKey(UInt32Char_t key, SMCVal_t *val, io_connect_t conn);
kern_return_t SMCWriteKey(SMCVal_t writeVal, io_connect_t conn);
kern_return_t SMCGetKeyInfo(UInt32 key, SMCKeyData_keyInfo_t *keyInfo, io_connect_t conn);

#endif
