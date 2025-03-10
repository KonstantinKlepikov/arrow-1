# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# distutils: language = c++

from pyarrow.includes.common cimport *

cdef extern from "arrow/util/key_value_metadata.h" namespace "arrow" nogil:
    cdef cppclass CKeyValueMetadata" arrow::KeyValueMetadata":
        CKeyValueMetadata()
        CKeyValueMetadata(const unordered_map[c_string, c_string]&)
        CKeyValueMetadata(const vector[c_string]& keys,
                          const vector[c_string]& values)

        void reserve(int64_t n)
        int64_t size() const
        c_string key(int64_t i) const
        c_string value(int64_t i) const

        c_bool Equals(const CKeyValueMetadata& other)
        void Append(const c_string& key, const c_string& value)
        void ToUnorderedMap(unordered_map[c_string, c_string]*) const


cdef extern from "arrow/api.h" namespace "arrow" nogil:

    enum Type" arrow::Type::type":
        _Type_NA" arrow::Type::NA"

        _Type_BOOL" arrow::Type::BOOL"

        _Type_UINT8" arrow::Type::UINT8"
        _Type_INT8" arrow::Type::INT8"
        _Type_UINT16" arrow::Type::UINT16"
        _Type_INT16" arrow::Type::INT16"
        _Type_UINT32" arrow::Type::UINT32"
        _Type_INT32" arrow::Type::INT32"
        _Type_UINT64" arrow::Type::UINT64"
        _Type_INT64" arrow::Type::INT64"

        _Type_HALF_FLOAT" arrow::Type::HALF_FLOAT"
        _Type_FLOAT" arrow::Type::FLOAT"
        _Type_DOUBLE" arrow::Type::DOUBLE"

        _Type_DECIMAL" arrow::Type::DECIMAL"

        _Type_DATE32" arrow::Type::DATE32"
        _Type_DATE64" arrow::Type::DATE64"
        _Type_TIMESTAMP" arrow::Type::TIMESTAMP"
        _Type_TIME32" arrow::Type::TIME32"
        _Type_TIME64" arrow::Type::TIME64"
        _Type_DURATION" arrow::Type::DURATION"

        _Type_BINARY" arrow::Type::BINARY"
        _Type_STRING" arrow::Type::STRING"
        _Type_LARGE_BINARY" arrow::Type::LARGE_BINARY"
        _Type_LARGE_STRING" arrow::Type::LARGE_STRING"
        _Type_FIXED_SIZE_BINARY" arrow::Type::FIXED_SIZE_BINARY"

        _Type_LIST" arrow::Type::LIST"
        _Type_LARGE_LIST" arrow::Type::LARGE_LIST"
        _Type_STRUCT" arrow::Type::STRUCT"
        _Type_UNION" arrow::Type::UNION"
        _Type_DICTIONARY" arrow::Type::DICTIONARY"
        _Type_MAP" arrow::Type::MAP"

        _Type_EXTENSION" arrow::Type::EXTENSION"

    enum UnionMode" arrow::UnionMode::type":
        _UnionMode_SPARSE" arrow::UnionMode::SPARSE"
        _UnionMode_DENSE" arrow::UnionMode::DENSE"

    enum TimeUnit" arrow::TimeUnit::type":
        TimeUnit_SECOND" arrow::TimeUnit::SECOND"
        TimeUnit_MILLI" arrow::TimeUnit::MILLI"
        TimeUnit_MICRO" arrow::TimeUnit::MICRO"
        TimeUnit_NANO" arrow::TimeUnit::NANO"

    cdef cppclass CDataTypeLayout" arrow::DataTypeLayout":
        vector[int64_t] bit_widths
        c_bool has_dictionary

    cdef cppclass CDataType" arrow::DataType":
        Type id()

        c_bool Equals(const CDataType& other)

        shared_ptr[CField] child(int i)

        const vector[shared_ptr[CField]] children()

        int num_children()

        CDataTypeLayout layout()

        c_string ToString()

    c_bool is_primitive(Type type)

    cdef cppclass CArrayData" arrow::ArrayData":
        shared_ptr[CDataType] type
        int64_t length
        int64_t null_count
        int64_t offset
        vector[shared_ptr[CBuffer]] buffers
        vector[shared_ptr[CArrayData]] child_data
        shared_ptr[CArray] dictionary

        @staticmethod
        shared_ptr[CArrayData] Make(const shared_ptr[CDataType]& type,
                                    int64_t length,
                                    vector[shared_ptr[CBuffer]]& buffers,
                                    int64_t null_count,
                                    int64_t offset)

        @staticmethod
        shared_ptr[CArrayData] MakeWithChildren" Make"(
            const shared_ptr[CDataType]& type,
            int64_t length,
            vector[shared_ptr[CBuffer]]& buffers,
            vector[shared_ptr[CArrayData]]& child_data,
            int64_t null_count,
            int64_t offset)

        @staticmethod
        shared_ptr[CArrayData] MakeWithChildrenAndDictionary" Make"(
            const shared_ptr[CDataType]& type,
            int64_t length,
            vector[shared_ptr[CBuffer]]& buffers,
            vector[shared_ptr[CArrayData]]& child_data,
            shared_ptr[CArray]& dictionary,
            int64_t null_count,
            int64_t offset)

    cdef cppclass CArray" arrow::Array":
        shared_ptr[CDataType] type()

        int64_t length()
        int64_t null_count()
        int64_t offset()
        Type type_id()

        int num_fields()

        c_string Diff(const CArray& other)
        c_bool Equals(const CArray& arr)
        c_bool IsNull(int i)

        shared_ptr[CArrayData] data()

        shared_ptr[CArray] Slice(int64_t offset)
        shared_ptr[CArray] Slice(int64_t offset, int64_t length)

        CStatus Validate() const
        CStatus View(const shared_ptr[CDataType]& type,
                     shared_ptr[CArray]* out)

    shared_ptr[CArray] MakeArray(const shared_ptr[CArrayData]& data)

    CStatus DebugPrint(const CArray& arr, int indent)

    cdef cppclass CFixedWidthType" arrow::FixedWidthType"(CDataType):
        int bit_width()

    cdef cppclass CNullArray" arrow::NullArray"(CArray):
        CNullArray(int64_t length)

    cdef cppclass CDictionaryArray" arrow::DictionaryArray"(CArray):
        CDictionaryArray(const shared_ptr[CDataType]& type,
                         const shared_ptr[CArray]& indices,
                         const shared_ptr[CArray]& dictionary)

        @staticmethod
        CStatus FromArrays(const shared_ptr[CDataType]& type,
                           const shared_ptr[CArray]& indices,
                           const shared_ptr[CArray]& dictionary,
                           shared_ptr[CArray]* out)

        shared_ptr[CArray] indices()
        shared_ptr[CArray] dictionary()

    cdef cppclass CDate32Type" arrow::Date32Type"(CFixedWidthType):
        pass

    cdef cppclass CDate64Type" arrow::Date64Type"(CFixedWidthType):
        pass

    cdef cppclass CTimestampType" arrow::TimestampType"(CFixedWidthType):
        CTimestampType(TimeUnit unit)
        TimeUnit unit()
        const c_string& timezone()

    cdef cppclass CTime32Type" arrow::Time32Type"(CFixedWidthType):
        TimeUnit unit()

    cdef cppclass CTime64Type" arrow::Time64Type"(CFixedWidthType):
        TimeUnit unit()

    shared_ptr[CDataType] ctime32" arrow::time32"(TimeUnit unit)
    shared_ptr[CDataType] ctime64" arrow::time64"(TimeUnit unit)

    cdef cppclass CDurationType" arrow::DurationType"(CFixedWidthType):
        TimeUnit unit()

    shared_ptr[CDataType] cduration" arrow::duration"(TimeUnit unit)

    cdef cppclass CDictionaryType" arrow::DictionaryType"(CFixedWidthType):
        CDictionaryType(const shared_ptr[CDataType]& index_type,
                        const shared_ptr[CDataType]& value_type,
                        c_bool ordered)

        shared_ptr[CDataType] index_type()
        shared_ptr[CDataType] value_type()
        c_bool ordered()

    shared_ptr[CDataType] ctimestamp" arrow::timestamp"(TimeUnit unit)
    shared_ptr[CDataType] ctimestamp" arrow::timestamp"(
        TimeUnit unit, const c_string& timezone)

    cdef cppclass CMemoryPool" arrow::MemoryPool":
        int64_t bytes_allocated()
        int64_t max_memory()

    cdef cppclass CLoggingMemoryPool" arrow::LoggingMemoryPool"(CMemoryPool):
        CLoggingMemoryPool(CMemoryPool*)

    cdef cppclass CProxyMemoryPool" arrow::ProxyMemoryPool"(CMemoryPool):
        CProxyMemoryPool(CMemoryPool*)

    cdef cppclass CBuffer" arrow::Buffer":
        CBuffer(const uint8_t* data, int64_t size)
        const uint8_t* data()
        uint8_t* mutable_data()
        int64_t size()
        shared_ptr[CBuffer] parent()
        c_bool is_mutable() const
        c_string ToHexString()
        c_bool Equals(const CBuffer& other)

    shared_ptr[CBuffer] SliceBuffer(const shared_ptr[CBuffer]& buffer,
                                    int64_t offset, int64_t length)
    shared_ptr[CBuffer] SliceBuffer(const shared_ptr[CBuffer]& buffer,
                                    int64_t offset)

    cdef cppclass CMutableBuffer" arrow::MutableBuffer"(CBuffer):
        CMutableBuffer(const uint8_t* data, int64_t size)

    cdef cppclass CResizableBuffer" arrow::ResizableBuffer"(CMutableBuffer):
        CStatus Resize(const int64_t new_size, c_bool shrink_to_fit)
        CStatus Reserve(const int64_t new_size)

    CStatus AllocateBuffer(CMemoryPool* pool, const int64_t size,
                           shared_ptr[CBuffer]* out)

    CStatus AllocateResizableBuffer(CMemoryPool* pool, const int64_t size,
                                    shared_ptr[CResizableBuffer]* out)

    cdef CMemoryPool* c_default_memory_pool" arrow::default_memory_pool"()

    CStatus c_jemalloc_set_decay_ms" arrow::jemalloc_set_decay_ms"(int ms)

    cdef cppclass CListType" arrow::ListType"(CDataType):
        CListType(const shared_ptr[CDataType]& value_type)
        CListType(const shared_ptr[CField]& field)
        shared_ptr[CDataType] value_type()
        shared_ptr[CField] value_field()

    cdef cppclass CLargeListType" arrow::LargeListType"(CDataType):
        CLargeListType(const shared_ptr[CDataType]& value_type)
        CLargeListType(const shared_ptr[CField]& field)
        shared_ptr[CDataType] value_type()
        shared_ptr[CField] value_field()

    cdef cppclass CStringType" arrow::StringType"(CDataType):
        pass

    cdef cppclass CFixedSizeBinaryType \
            " arrow::FixedSizeBinaryType"(CFixedWidthType):
        CFixedSizeBinaryType(int byte_width)
        int byte_width()
        int bit_width()

    cdef cppclass CDecimal128Type \
            " arrow::Decimal128Type"(CFixedSizeBinaryType):
        CDecimal128Type(int precision, int scale)
        int precision()
        int scale()

    cdef cppclass CField" arrow::Field":
        const c_string& name()
        shared_ptr[CDataType] type()
        c_bool nullable()

        c_string ToString()
        c_bool Equals(const CField& other)

        shared_ptr[const CKeyValueMetadata] metadata()

        CField(const c_string& name, const shared_ptr[CDataType]& type,
               c_bool nullable)

        CField(const c_string& name, const shared_ptr[CDataType]& type,
               c_bool nullable, const shared_ptr[CKeyValueMetadata]& metadata)

        # Removed const in Cython so don't have to cast to get code to generate
        shared_ptr[CField] AddMetadata(
            const shared_ptr[CKeyValueMetadata]& metadata)
        shared_ptr[CField] WithMetadata(
            const shared_ptr[CKeyValueMetadata]& metadata)
        shared_ptr[CField] RemoveMetadata()
        vector[shared_ptr[CField]] Flatten()

    cdef cppclass CStructType" arrow::StructType"(CDataType):
        CStructType(const vector[shared_ptr[CField]]& fields)

        shared_ptr[CField] GetFieldByName(const c_string& name)
        vector[shared_ptr[CField]] GetAllFieldsByName(const c_string& name)
        int GetFieldIndex(const c_string& name)

    cdef cppclass CUnionType" arrow::UnionType"(CDataType):
        CUnionType(const vector[shared_ptr[CField]]& fields,
                   const vector[uint8_t]& type_codes, UnionMode mode)
        UnionMode mode()
        const vector[uint8_t]& type_codes()

    cdef cppclass CSchema" arrow::Schema":
        CSchema(const vector[shared_ptr[CField]]& fields)
        CSchema(const vector[shared_ptr[CField]]& fields,
                const shared_ptr[const CKeyValueMetadata]& metadata)

        # Does not actually exist, but gets Cython to not complain
        CSchema(const vector[shared_ptr[CField]]& fields,
                const shared_ptr[CKeyValueMetadata]& metadata)

        c_bool Equals(const CSchema& other, c_bool check_metadata)

        shared_ptr[CField] field(int i)
        shared_ptr[const CKeyValueMetadata] metadata()
        shared_ptr[CField] GetFieldByName(const c_string& name)
        vector[shared_ptr[CField]] GetAllFieldsByName(const c_string& name)
        int64_t GetFieldIndex(const c_string& name)
        vector[int64_t] GetAllFieldIndice(const c_string& name)
        int num_fields()
        c_string ToString()

        CStatus AddField(int i, const shared_ptr[CField]& field,
                         shared_ptr[CSchema]* out)
        CStatus RemoveField(int i, shared_ptr[CSchema]* out)
        CStatus SetField(int i, const shared_ptr[CField]& field,
                         shared_ptr[CSchema]* out)

        # Removed const in Cython so don't have to cast to get code to generate
        shared_ptr[CSchema] AddMetadata(
            const shared_ptr[CKeyValueMetadata]& metadata)
        shared_ptr[CSchema] WithMetadata(
            const shared_ptr[CKeyValueMetadata]& metadata)
        shared_ptr[CSchema] RemoveMetadata()

    cdef cppclass PrettyPrintOptions:
        PrettyPrintOptions(int indent_arg)
        PrettyPrintOptions(int indent_arg, int window_arg)
        int indent
        int window

    CStatus PrettyPrint(const CArray& schema,
                        const PrettyPrintOptions& options,
                        c_string* result)
    CStatus PrettyPrint(const CChunkedArray& schema,
                        const PrettyPrintOptions& options,
                        c_string* result)
    CStatus PrettyPrint(const CSchema& schema,
                        const PrettyPrintOptions& options,
                        c_string* result)

    cdef cppclass CBooleanArray" arrow::BooleanArray"(CArray):
        c_bool Value(int i)

    cdef cppclass CUInt8Array" arrow::UInt8Array"(CArray):
        uint8_t Value(int i)

    cdef cppclass CInt8Array" arrow::Int8Array"(CArray):
        int8_t Value(int i)

    cdef cppclass CUInt16Array" arrow::UInt16Array"(CArray):
        uint16_t Value(int i)

    cdef cppclass CInt16Array" arrow::Int16Array"(CArray):
        int16_t Value(int i)

    cdef cppclass CUInt32Array" arrow::UInt32Array"(CArray):
        uint32_t Value(int i)

    cdef cppclass CInt32Array" arrow::Int32Array"(CArray):
        int32_t Value(int i)

    cdef cppclass CUInt64Array" arrow::UInt64Array"(CArray):
        uint64_t Value(int i)

    cdef cppclass CInt64Array" arrow::Int64Array"(CArray):
        int64_t Value(int i)

    cdef cppclass CDate32Array" arrow::Date32Array"(CArray):
        int32_t Value(int i)

    cdef cppclass CDate64Array" arrow::Date64Array"(CArray):
        int64_t Value(int i)

    cdef cppclass CTime32Array" arrow::Time32Array"(CArray):
        int32_t Value(int i)

    cdef cppclass CTime64Array" arrow::Time64Array"(CArray):
        int64_t Value(int i)

    cdef cppclass CTimestampArray" arrow::TimestampArray"(CArray):
        int64_t Value(int i)

    cdef cppclass CDurationArray" arrow::DurationArray"(CArray):
        int64_t Value(int i)

    cdef cppclass CHalfFloatArray" arrow::HalfFloatArray"(CArray):
        uint16_t Value(int i)

    cdef cppclass CFloatArray" arrow::FloatArray"(CArray):
        float Value(int i)

    cdef cppclass CDoubleArray" arrow::DoubleArray"(CArray):
        double Value(int i)

    cdef cppclass CFixedSizeBinaryArray" arrow::FixedSizeBinaryArray"(CArray):
        const uint8_t* GetValue(int i)

    cdef cppclass CDecimal128Array" arrow::Decimal128Array"(
        CFixedSizeBinaryArray
    ):
        c_string FormatValue(int i)

    cdef cppclass CListArray" arrow::ListArray"(CArray):
        @staticmethod
        CStatus FromArrays(const CArray& offsets, const CArray& values,
                           CMemoryPool* pool, shared_ptr[CArray]* out)

        const int32_t* raw_value_offsets()
        int32_t value_offset(int i)
        int32_t value_length(int i)
        shared_ptr[CArray] values()
        shared_ptr[CDataType] value_type()

    cdef cppclass CLargeListArray" arrow::LargeListArray"(CArray):
        @staticmethod
        CStatus FromArrays(const CArray& offsets, const CArray& values,
                           CMemoryPool* pool, shared_ptr[CArray]* out)

        const int64_t* raw_value_offsets()
        int64_t value_offset(int i)
        int64_t value_length(int i)
        shared_ptr[CArray] values()
        shared_ptr[CDataType] value_type()

    cdef cppclass CUnionArray" arrow::UnionArray"(CArray):
        @staticmethod
        CStatus MakeSparse(const CArray& type_ids,
                           const vector[shared_ptr[CArray]]& children,
                           const vector[c_string]& field_names,
                           const vector[uint8_t]& type_codes,
                           shared_ptr[CArray]* out)

        @staticmethod
        CStatus MakeDense(const CArray& type_ids, const CArray& value_offsets,
                          const vector[shared_ptr[CArray]]& children,
                          const vector[c_string]& field_names,
                          const vector[uint8_t]& type_codes,
                          shared_ptr[CArray]* out)
        uint8_t* raw_type_ids()
        int32_t value_offset(int i)
        shared_ptr[CArray] child(int pos)
        const CArray* UnsafeChild(int pos)
        UnionMode mode()

    cdef cppclass CBinaryArray" arrow::BinaryArray"(CArray):
        const uint8_t* GetValue(int i, int32_t* length)
        shared_ptr[CBuffer] value_data()
        int32_t value_offset(int64_t i)
        int32_t value_length(int64_t i)

    cdef cppclass CLargeBinaryArray" arrow::LargeBinaryArray"(CArray):
        const uint8_t* GetValue(int i, int64_t* length)
        shared_ptr[CBuffer] value_data()
        int64_t value_offset(int64_t i)
        int64_t value_length(int64_t i)

    cdef cppclass CStringArray" arrow::StringArray"(CBinaryArray):
        CStringArray(int64_t length, shared_ptr[CBuffer] value_offsets,
                     shared_ptr[CBuffer] data,
                     shared_ptr[CBuffer] null_bitmap,
                     int64_t null_count,
                     int64_t offset)

        c_string GetString(int i)

    cdef cppclass CLargeStringArray" arrow::LargeStringArray" \
            (CLargeBinaryArray):
        CLargeStringArray(int64_t length, shared_ptr[CBuffer] value_offsets,
                          shared_ptr[CBuffer] data,
                          shared_ptr[CBuffer] null_bitmap,
                          int64_t null_count,
                          int64_t offset)

        c_string GetString(int i)

    cdef cppclass CStructArray" arrow::StructArray"(CArray):
        CStructArray(shared_ptr[CDataType] type, int64_t length,
                     vector[shared_ptr[CArray]] children,
                     shared_ptr[CBuffer] null_bitmap=nullptr,
                     int64_t null_count=-1,
                     int64_t offset=0)

        # XXX Cython crashes if default argument values are declared here
        # https://github.com/cython/cython/issues/2167
        @staticmethod
        CResult[shared_ptr[CArray]] MakeFromFieldNames "Make"(
            vector[shared_ptr[CArray]] children,
            vector[c_string] field_names,
            shared_ptr[CBuffer] null_bitmap,
            int64_t null_count,
            int64_t offset)

        @staticmethod
        CResult[shared_ptr[CArray]] MakeFromFields "Make"(
            vector[shared_ptr[CArray]] children,
            vector[shared_ptr[CField]] fields,
            shared_ptr[CBuffer] null_bitmap,
            int64_t null_count,
            int64_t offset)

        shared_ptr[CArray] field(int pos)
        shared_ptr[CArray] GetFieldByName(const c_string& name) const

        CStatus Flatten(CMemoryPool* pool, vector[shared_ptr[CArray]]* out)

    cdef cppclass CChunkedArray" arrow::ChunkedArray":
        CChunkedArray(const vector[shared_ptr[CArray]]& arrays)
        CChunkedArray(const vector[shared_ptr[CArray]]& arrays,
                      const shared_ptr[CDataType]& type)
        int64_t length()
        int64_t null_count()
        int num_chunks()
        c_bool Equals(const CChunkedArray& other)

        shared_ptr[CArray] chunk(int i)
        shared_ptr[CDataType] type()
        shared_ptr[CChunkedArray] Slice(int64_t offset, int64_t length) const
        shared_ptr[CChunkedArray] Slice(int64_t offset) const

        CStatus Flatten(CMemoryPool* pool,
                        vector[shared_ptr[CChunkedArray]]* out)

        CStatus Validate() const

    cdef cppclass CRecordBatch" arrow::RecordBatch":
        @staticmethod
        shared_ptr[CRecordBatch] Make(
            const shared_ptr[CSchema]& schema, int64_t num_rows,
            const vector[shared_ptr[CArray]]& columns)

        c_bool Equals(const CRecordBatch& other)

        shared_ptr[CSchema] schema()
        shared_ptr[CArray] column(int i)
        const c_string& column_name(int i)

        const vector[shared_ptr[CArray]]& columns()

        int num_columns()
        int64_t num_rows()

        CStatus Validate()

        shared_ptr[CRecordBatch] ReplaceSchemaMetadata(
            const shared_ptr[CKeyValueMetadata]& metadata)

        shared_ptr[CRecordBatch] Slice(int64_t offset)
        shared_ptr[CRecordBatch] Slice(int64_t offset, int64_t length)

    cdef cppclass CTable" arrow::Table":
        CTable(const shared_ptr[CSchema]& schema,
               const vector[shared_ptr[CChunkedArray]]& columns)

        @staticmethod
        shared_ptr[CTable] Make(
            const shared_ptr[CSchema]& schema,
            const vector[shared_ptr[CChunkedArray]]& columns)

        @staticmethod
        shared_ptr[CTable] MakeFromArrays" Make"(
            const shared_ptr[CSchema]& schema,
            const vector[shared_ptr[CArray]]& arrays)

        @staticmethod
        CStatus FromRecordBatches(
            const shared_ptr[CSchema]& schema,
            const vector[shared_ptr[CRecordBatch]]& batches,
            shared_ptr[CTable]* table)

        int num_columns()
        int64_t num_rows()

        c_bool Equals(const CTable& other)

        shared_ptr[CSchema] schema()
        shared_ptr[CChunkedArray] column(int i)
        shared_ptr[CField] field(int i)

        CStatus AddColumn(int i, shared_ptr[CField] field,
                          shared_ptr[CChunkedArray] column,
                          shared_ptr[CTable]* out)
        CStatus RemoveColumn(int i, shared_ptr[CTable]* out)
        CStatus SetColumn(int i, shared_ptr[CField] field,
                          shared_ptr[CChunkedArray] column,
                          shared_ptr[CTable]* out)

        vector[c_string] ColumnNames()
        CStatus RenameColumns(const vector[c_string]&, shared_ptr[CTable]* out)

        CStatus Flatten(CMemoryPool* pool, shared_ptr[CTable]* out)

        CStatus CombineChunks(CMemoryPool* pool, shared_ptr[CTable]* out)

        CStatus Validate()

        shared_ptr[CTable] ReplaceSchemaMetadata(
            const shared_ptr[CKeyValueMetadata]& metadata)

        shared_ptr[CTable] Slice(int64_t offset)
        shared_ptr[CTable] Slice(int64_t offset, int64_t length)

    cdef cppclass CRecordBatchReader" arrow::RecordBatchReader":
        shared_ptr[CSchema] schema()
        CStatus ReadNext(shared_ptr[CRecordBatch]* batch)
        CStatus ReadAll(shared_ptr[CTable]* out)

    cdef cppclass TableBatchReader(CRecordBatchReader):
        TableBatchReader(const CTable& table)
        void set_chunksize(int64_t chunksize)

    cdef cppclass CTensor" arrow::Tensor":
        shared_ptr[CDataType] type()
        shared_ptr[CBuffer] data()

        const vector[int64_t]& shape()
        const vector[int64_t]& strides()
        int64_t size()

        int ndim()
        const vector[c_string]& dim_names()
        const c_string& dim_name(int i)

        c_bool is_mutable()
        c_bool is_contiguous()
        Type type_id()
        c_bool Equals(const CTensor& other)

    cdef cppclass CSparseCOOTensor" arrow::SparseCOOTensor":
        shared_ptr[CDataType] type()
        shared_ptr[CBuffer] data()
        CStatus ToTensor(shared_ptr[CTensor]*)

        const vector[int64_t]& shape()
        int64_t size()
        int64_t non_zero_length()

        int ndim()
        const vector[c_string]& dim_names()
        const c_string& dim_name(int i)

        c_bool is_mutable()
        Type type_id()
        c_bool Equals(const CSparseCOOTensor& other)

    cdef cppclass CSparseCSRMatrix" arrow::SparseCSRMatrix":
        shared_ptr[CDataType] type()
        shared_ptr[CBuffer] data()
        CStatus ToTensor(shared_ptr[CTensor]*)

        const vector[int64_t]& shape()
        int64_t size()
        int64_t non_zero_length()

        int ndim()
        const vector[c_string]& dim_names()
        const c_string& dim_name(int i)

        c_bool is_mutable()
        Type type_id()
        c_bool Equals(const CSparseCSRMatrix& other)

    cdef cppclass CScalar" arrow::Scalar":
        shared_ptr[CDataType] type

    cdef cppclass CInt8Scalar" arrow::Int8Scalar"(CScalar):
        int8_t value

    cdef cppclass CUInt8Scalar" arrow::UInt8Scalar"(CScalar):
        uint8_t value

    cdef cppclass CInt16Scalar" arrow::Int16Scalar"(CScalar):
        int16_t value

    cdef cppclass CUInt16Scalar" arrow::UInt16Scalar"(CScalar):
        uint16_t value

    cdef cppclass CInt32Scalar" arrow::Int32Scalar"(CScalar):
        int32_t value

    cdef cppclass CUInt32Scalar" arrow::UInt32Scalar"(CScalar):
        uint32_t value

    cdef cppclass CInt64Scalar" arrow::Int64Scalar"(CScalar):
        int64_t value

    cdef cppclass CUInt64Scalar" arrow::UInt64Scalar"(CScalar):
        uint64_t value

    cdef cppclass CFloatScalar" arrow::FloatScalar"(CScalar):
        float value

    cdef cppclass CDoubleScalar" arrow::DoubleScalar"(CScalar):
        double value

    CStatus ConcatenateTables(const vector[shared_ptr[CTable]]& tables,
                              shared_ptr[CTable]* result)

cdef extern from "arrow/builder.h" namespace "arrow" nogil:

    cdef cppclass CArrayBuilder" arrow::ArrayBuilder":
        CArrayBuilder(shared_ptr[CDataType], CMemoryPool* pool)

        int64_t length()
        int64_t null_count()
        CStatus AppendNull()
        CStatus Finish(shared_ptr[CArray]* out)
        CStatus Reserve(int64_t additional_capacity)

    cdef cppclass CBooleanBuilder" arrow::BooleanBuilder"(CArrayBuilder):
        CBooleanBuilder(CMemoryPool* pool)
        CStatus Append(const bint val)
        CStatus Append(const uint8_t val)

    cdef cppclass CInt8Builder" arrow::Int8Builder"(CArrayBuilder):
        CInt8Builder(CMemoryPool* pool)
        CStatus Append(const int8_t value)

    cdef cppclass CInt16Builder" arrow::Int16Builder"(CArrayBuilder):
        CInt16Builder(CMemoryPool* pool)
        CStatus Append(const int16_t value)

    cdef cppclass CInt32Builder" arrow::Int32Builder"(CArrayBuilder):
        CInt32Builder(CMemoryPool* pool)
        CStatus Append(const int32_t value)

    cdef cppclass CInt64Builder" arrow::Int64Builder"(CArrayBuilder):
        CInt64Builder(CMemoryPool* pool)
        CStatus Append(const int64_t value)

    cdef cppclass CUInt8Builder" arrow::UInt8Builder"(CArrayBuilder):
        CUInt8Builder(CMemoryPool* pool)
        CStatus Append(const uint8_t value)

    cdef cppclass CUInt16Builder" arrow::UInt16Builder"(CArrayBuilder):
        CUInt16Builder(CMemoryPool* pool)
        CStatus Append(const uint16_t value)

    cdef cppclass CUInt32Builder" arrow::UInt32Builder"(CArrayBuilder):
        CUInt32Builder(CMemoryPool* pool)
        CStatus Append(const uint32_t value)

    cdef cppclass CUInt64Builder" arrow::UInt64Builder"(CArrayBuilder):
        CUInt64Builder(CMemoryPool* pool)
        CStatus Append(const uint64_t value)

    cdef cppclass CHalfFloatBuilder" arrow::HalfFloatBuilder"(CArrayBuilder):
        CHalfFloatBuilder(CMemoryPool* pool)

    cdef cppclass CFloatBuilder" arrow::FloatBuilder"(CArrayBuilder):
        CFloatBuilder(CMemoryPool* pool)
        CStatus Append(const float value)

    cdef cppclass CDoubleBuilder" arrow::DoubleBuilder"(CArrayBuilder):
        CDoubleBuilder(CMemoryPool* pool)
        CStatus Append(const double value)

    cdef cppclass CBinaryBuilder" arrow::BinaryBuilder"(CArrayBuilder):
        CArrayBuilder(shared_ptr[CDataType], CMemoryPool* pool)
        CStatus Append(const char* value, int32_t length)

    cdef cppclass CStringBuilder" arrow::StringBuilder"(CBinaryBuilder):
        CStringBuilder(CMemoryPool* pool)

        CStatus Append(const c_string& value)

    cdef cppclass CTimestampBuilder "arrow::TimestampBuilder"(CArrayBuilder):
        CTimestampBuilder(const shared_ptr[CDataType] typ, CMemoryPool* pool)
        CStatus Append(const int64_t value)

    cdef cppclass CDate32Builder "arrow::Date32Builder"(CArrayBuilder):
        CDate32Builder(CMemoryPool* pool)
        CStatus Append(const int32_t value)

    cdef cppclass CDate64Builder "arrow::Date64Builder"(CArrayBuilder):
        CDate64Builder(CMemoryPool* pool)
        CStatus Append(const int64_t value)


cdef extern from "arrow/io/api.h" namespace "arrow::io" nogil:
    enum FileMode" arrow::io::FileMode::type":
        FileMode_READ" arrow::io::FileMode::READ"
        FileMode_WRITE" arrow::io::FileMode::WRITE"
        FileMode_READWRITE" arrow::io::FileMode::READWRITE"

    enum ObjectType" arrow::io::ObjectType::type":
        ObjectType_FILE" arrow::io::ObjectType::FILE"
        ObjectType_DIRECTORY" arrow::io::ObjectType::DIRECTORY"

    cdef cppclass FileStatistics:
        int64_t size
        ObjectType kind

    cdef cppclass FileInterface:
        CStatus Close()
        CStatus Tell(int64_t* position)
        FileMode mode()
        c_bool closed()

    cdef cppclass Readable:
        # put overload under a different name to avoid cython bug with multiple
        # layers of inheritance
        CStatus ReadBuffer" Read"(int64_t nbytes, shared_ptr[CBuffer]* out)
        CStatus Read(int64_t nbytes, int64_t* bytes_read, uint8_t* out)

    cdef cppclass Seekable:
        CStatus Seek(int64_t position)

    cdef cppclass Writable:
        CStatus WriteBuffer" Write"(shared_ptr[CBuffer] data)
        CStatus Write(const uint8_t* data, int64_t nbytes)
        CStatus Flush()

    cdef cppclass COutputStream" arrow::io::OutputStream"(FileInterface,
                                                          Writable):
        pass

    cdef cppclass CInputStream" arrow::io::InputStream"(FileInterface,
                                                        Readable):
        pass

    cdef cppclass CRandomAccessFile" arrow::io::RandomAccessFile"(CInputStream,
                                                                  Seekable):
        CStatus GetSize(int64_t* size)

        CStatus ReadAt(int64_t position, int64_t nbytes,
                       int64_t* bytes_read, uint8_t* buffer)
        CStatus ReadAt(int64_t position, int64_t nbytes,
                       shared_ptr[CBuffer]* out)
        c_bool supports_zero_copy()

    cdef cppclass WritableFile(COutputStream, Seekable):
        CStatus WriteAt(int64_t position, const uint8_t* data,
                        int64_t nbytes)

    cdef cppclass ReadWriteFileInterface(CRandomAccessFile,
                                         WritableFile):
        pass

    cdef cppclass CIOFileSystem" arrow::io::FileSystem":
        CStatus Stat(const c_string& path, FileStatistics* stat)

    cdef cppclass FileOutputStream(COutputStream):
        @staticmethod
        CStatus Open(const c_string& path, shared_ptr[COutputStream]* file)

        int file_descriptor()

    cdef cppclass ReadableFile(CRandomAccessFile):
        @staticmethod
        CStatus Open(const c_string& path, shared_ptr[ReadableFile]* file)

        @staticmethod
        CStatus Open(const c_string& path, CMemoryPool* memory_pool,
                     shared_ptr[ReadableFile]* file)

        int file_descriptor()

    cdef cppclass CMemoryMappedFile \
            " arrow::io::MemoryMappedFile"(ReadWriteFileInterface):

        @staticmethod
        CStatus Create(const c_string& path, int64_t size,
                       shared_ptr[CMemoryMappedFile]* file)

        @staticmethod
        CStatus Open(const c_string& path, FileMode mode,
                     shared_ptr[CMemoryMappedFile]* file)

        CStatus Resize(int64_t size)

        int file_descriptor()

    cdef cppclass CCompressedInputStream \
            " arrow::io::CompressedInputStream"(CInputStream):
        @staticmethod
        CStatus Make(CMemoryPool* pool, CCodec* codec,
                     shared_ptr[CInputStream] raw,
                     shared_ptr[CCompressedInputStream]* out)

        @staticmethod
        CStatus Make(CCodec* codec, shared_ptr[CInputStream] raw,
                     shared_ptr[CCompressedInputStream]* out)

    cdef cppclass CCompressedOutputStream \
            " arrow::io::CompressedOutputStream"(COutputStream):
        @staticmethod
        CStatus Make(CMemoryPool* pool, CCodec* codec,
                     shared_ptr[COutputStream] raw,
                     shared_ptr[CCompressedOutputStream]* out)

        @staticmethod
        CStatus Make(CCodec* codec, shared_ptr[COutputStream] raw,
                     shared_ptr[CCompressedOutputStream]* out)

    cdef cppclass CBufferedInputStream \
            " arrow::io::BufferedInputStream"(CInputStream):

        @staticmethod
        CStatus Create(int64_t buffer_size, CMemoryPool* pool,
                       shared_ptr[CInputStream] raw,
                       shared_ptr[CBufferedInputStream]* out)

        shared_ptr[CInputStream] Detach()

    cdef cppclass CBufferedOutputStream \
            " arrow::io::BufferedOutputStream"(COutputStream):

        @staticmethod
        CStatus Create(int64_t buffer_size, CMemoryPool* pool,
                       shared_ptr[COutputStream] raw,
                       shared_ptr[CBufferedOutputStream]* out)

        CStatus Detach(shared_ptr[COutputStream]* raw)

    # ----------------------------------------------------------------------
    # HDFS

    CStatus HaveLibHdfs()
    CStatus HaveLibHdfs3()

    enum HdfsDriver" arrow::io::HdfsDriver":
        HdfsDriver_LIBHDFS" arrow::io::HdfsDriver::LIBHDFS"
        HdfsDriver_LIBHDFS3" arrow::io::HdfsDriver::LIBHDFS3"

    cdef cppclass HdfsConnectionConfig:
        c_string host
        int port
        c_string user
        c_string kerb_ticket
        unordered_map[c_string, c_string] extra_conf
        HdfsDriver driver

    cdef cppclass HdfsPathInfo:
        ObjectType kind
        c_string name
        c_string owner
        c_string group
        int32_t last_modified_time
        int32_t last_access_time
        int64_t size
        int16_t replication
        int64_t block_size
        int16_t permissions

    cdef cppclass HdfsReadableFile(CRandomAccessFile):
        pass

    cdef cppclass HdfsOutputStream(COutputStream):
        pass

    cdef cppclass CHadoopFileSystem \
            "arrow::io::HadoopFileSystem"(CIOFileSystem):
        @staticmethod
        CStatus Connect(const HdfsConnectionConfig* config,
                        shared_ptr[CHadoopFileSystem]* client)

        CStatus MakeDirectory(const c_string& path)

        CStatus Delete(const c_string& path, c_bool recursive)

        CStatus Disconnect()

        c_bool Exists(const c_string& path)

        CStatus Chmod(const c_string& path, int mode)
        CStatus Chown(const c_string& path, const char* owner,
                      const char* group)

        CStatus GetCapacity(int64_t* nbytes)
        CStatus GetUsed(int64_t* nbytes)

        CStatus ListDirectory(const c_string& path,
                              vector[HdfsPathInfo]* listing)

        CStatus GetPathInfo(const c_string& path, HdfsPathInfo* info)

        CStatus Rename(const c_string& src, const c_string& dst)

        CStatus OpenReadable(const c_string& path,
                             shared_ptr[HdfsReadableFile]* handle)

        CStatus OpenWritable(const c_string& path, c_bool append,
                             int32_t buffer_size, int16_t replication,
                             int64_t default_block_size,
                             shared_ptr[HdfsOutputStream]* handle)

    cdef cppclass CBufferReader \
            " arrow::io::BufferReader"(CRandomAccessFile):
        CBufferReader(const shared_ptr[CBuffer]& buffer)
        CBufferReader(const uint8_t* data, int64_t nbytes)

    cdef cppclass CBufferOutputStream \
            " arrow::io::BufferOutputStream"(COutputStream):
        CBufferOutputStream(const shared_ptr[CResizableBuffer]& buffer)

    cdef cppclass CMockOutputStream \
            " arrow::io::MockOutputStream"(COutputStream):
        CMockOutputStream()
        int64_t GetExtentBytesWritten()

    cdef cppclass CFixedSizeBufferWriter \
            " arrow::io::FixedSizeBufferWriter"(WritableFile):
        CFixedSizeBufferWriter(const shared_ptr[CBuffer]& buffer)

        void set_memcopy_threads(int num_threads)
        void set_memcopy_blocksize(int64_t blocksize)
        void set_memcopy_threshold(int64_t threshold)


cdef extern from "arrow/filesystem/api.h" namespace "arrow::fs" nogil:

    ctypedef enum CFileType "arrow::fs::FileType":
        CFileType_NonExistent "arrow::fs::FileType::NonExistent"
        CFileType_Unknown "arrow::fs::FileType::Unknown"
        CFileType_File "arrow::fs::FileType::File"
        CFileType_Directory "arrow::fs::FileType::Directory"

    cdef cppclass CTimePoint "arrow::fs::TimePoint":
        pass

    cdef cppclass CFileStats "arrow::fs::FileStats":
        CFileStats()
        CFileStats(CFileStats&&)
        CFileStats& operator=(CFileStats&&)
        CFileStats(const CFileStats&)
        CFileStats& operator=(const CFileStats&)

        CFileType type()
        void set_type(CFileType type)
        c_string path()
        void set_path(const c_string& path)
        c_string base_name()
        int64_t size()
        void set_size(int64_t size)
        c_string extension()
        CTimePoint mtime()
        void set_mtime(CTimePoint mtime)

    cdef cppclass CSelector "arrow::fs::Selector":
        CSelector()
        c_string base_dir
        c_bool allow_non_existent
        c_bool recursive

    cdef cppclass CFileSystem "arrow::fs::FileSystem":
        CResult[CFileStats] GetTargetStats(const c_string& path)
        CResult[vector[CFileStats]] GetTargetStats(
            const vector[c_string]& paths)
        CResult[vector[CFileStats]] GetTargetStats(const CSelector& select)
        CStatus CreateDir(const c_string& path, c_bool recursive)
        CStatus DeleteDir(const c_string& path)
        CStatus DeleteFile(const c_string& path)
        CStatus DeleteFiles(const vector[c_string]& paths)
        CStatus Move(const c_string& src, const c_string& dest)
        CStatus CopyFile(const c_string& src, const c_string& dest)
        CResult[shared_ptr[CInputStream]] OpenInputStream(
            const c_string& path)
        CResult[shared_ptr[CRandomAccessFile]] OpenInputFile(
            const c_string& path)
        CResult[shared_ptr[COutputStream]] OpenOutputStream(
            const c_string& path)
        CResult[shared_ptr[COutputStream]] OpenAppendStream(
            const c_string& path)

    cdef cppclass CLocalFileSystemOptions "arrow::fs::LocalFileSystemOptions":
        c_bool use_mmap

        @staticmethod
        CLocalFileSystemOptions Defaults()

    cdef cppclass CLocalFileSystem "arrow::fs::LocalFileSystem"(CFileSystem):
        CLocalFileSystem()
        CLocalFileSystem(CLocalFileSystemOptions)

    cdef cppclass CSubTreeFileSystem \
            "arrow::fs::SubTreeFileSystem"(CFileSystem):
        CSubTreeFileSystem(const c_string& base_path,
                           shared_ptr[CFileSystem] base_fs)


cdef extern from "arrow/ipc/api.h" namespace "arrow::ipc" nogil:
    enum MessageType" arrow::ipc::Message::Type":
        MessageType_SCHEMA" arrow::ipc::Message::SCHEMA"
        MessageType_RECORD_BATCH" arrow::ipc::Message::RECORD_BATCH"
        MessageType_DICTIONARY_BATCH" arrow::ipc::Message::DICTIONARY_BATCH"

    enum MetadataVersion" arrow::ipc::MetadataVersion":
        MessageType_V1" arrow::ipc::MetadataVersion::V1"
        MessageType_V2" arrow::ipc::MetadataVersion::V2"
        MessageType_V3" arrow::ipc::MetadataVersion::V3"
        MessageType_V4" arrow::ipc::MetadataVersion::V4"

    cdef cppclass CIpcOptions" arrow::ipc::IpcOptions":
        c_bool allow_64bit
        int max_recursion_depth
        int32_t alignment
        c_bool write_legacy_ipc_format

        @staticmethod
        CIpcOptions Defaults()

    cdef cppclass CDictionaryMemo" arrow::ipc::DictionaryMemo":
        pass

    cdef cppclass CIpcPayload" arrow::ipc::internal::IpcPayload":
        MessageType type
        shared_ptr[CBuffer] metadata
        vector[shared_ptr[CBuffer]] body_buffers
        int64_t body_length

    cdef cppclass CMessage" arrow::ipc::Message":
        CStatus Open(const shared_ptr[CBuffer]& metadata,
                     const shared_ptr[CBuffer]& body,
                     unique_ptr[CMessage]* out)

        shared_ptr[CBuffer] body()

        c_bool Equals(const CMessage& other)

        shared_ptr[CBuffer] metadata()
        MetadataVersion metadata_version()
        MessageType type()

        CStatus SerializeTo(COutputStream* stream, const CIpcOptions& options,
                            int64_t* output_length)

    c_string FormatMessageType(MessageType type)

    cdef cppclass CMessageReader" arrow::ipc::MessageReader":
        @staticmethod
        unique_ptr[CMessageReader] Open(const shared_ptr[CInputStream]& stream)

        CStatus ReadNextMessage(unique_ptr[CMessage]* out)

    cdef cppclass CRecordBatchWriter" arrow::ipc::RecordBatchWriter":
        CStatus Close()
        CStatus WriteRecordBatch(const CRecordBatch& batch)
        CStatus WriteTable(const CTable& table, int64_t max_chunksize)

    cdef cppclass CRecordBatchStreamReader \
            " arrow::ipc::RecordBatchStreamReader"(CRecordBatchReader):
        @staticmethod
        CStatus Open(const CInputStream* stream,
                     shared_ptr[CRecordBatchReader]* out)

        @staticmethod
        CStatus Open2" Open"(unique_ptr[CMessageReader] message_reader,
                             shared_ptr[CRecordBatchReader]* out)

    cdef cppclass CRecordBatchStreamWriter \
            " arrow::ipc::RecordBatchStreamWriter"(CRecordBatchWriter):
        @staticmethod
        CResult[shared_ptr[CRecordBatchWriter]] Open(
            COutputStream* sink, const shared_ptr[CSchema]& schema,
            CIpcOptions& options)

    cdef cppclass CRecordBatchFileWriter \
            " arrow::ipc::RecordBatchFileWriter"(CRecordBatchWriter):
        @staticmethod
        CResult[shared_ptr[CRecordBatchWriter]] Open(
            COutputStream* sink, const shared_ptr[CSchema]& schema,
            CIpcOptions& options)

    cdef cppclass CRecordBatchFileReader \
            " arrow::ipc::RecordBatchFileReader":
        @staticmethod
        CStatus Open(CRandomAccessFile* file,
                     shared_ptr[CRecordBatchFileReader]* out)

        @staticmethod
        CStatus Open2" Open"(CRandomAccessFile* file,
                             int64_t footer_offset,
                             shared_ptr[CRecordBatchFileReader]* out)

        shared_ptr[CSchema] schema()

        int num_record_batches()

        CStatus ReadRecordBatch(int i, shared_ptr[CRecordBatch]* batch)

    CStatus ReadMessage(CInputStream* stream, unique_ptr[CMessage]* message)

    CStatus GetRecordBatchSize(const CRecordBatch& batch, int64_t* size)
    CStatus GetTensorSize(const CTensor& tensor, int64_t* size)

    CStatus WriteTensor(const CTensor& tensor, COutputStream* dst,
                        int32_t* metadata_length,
                        int64_t* body_length)

    CStatus ReadTensor(CInputStream* stream, shared_ptr[CTensor]* out)

    CStatus ReadRecordBatch(const CMessage& message,
                            const shared_ptr[CSchema]& schema,
                            CDictionaryMemo* dictionary_memo,
                            shared_ptr[CRecordBatch]* out)

    CStatus SerializeSchema(const CSchema& schema,
                            CDictionaryMemo* dictionary_memo,
                            CMemoryPool* pool, shared_ptr[CBuffer]* out)

    CStatus SerializeRecordBatch(const CRecordBatch& schema,
                                 CMemoryPool* pool,
                                 shared_ptr[CBuffer]* out)

    CStatus ReadSchema(CInputStream* stream, CDictionaryMemo* dictionary_memo,
                       shared_ptr[CSchema]* out)

    CStatus ReadRecordBatch(const shared_ptr[CSchema]& schema,
                            CDictionaryMemo* dictionary_memo,
                            CInputStream* stream,
                            shared_ptr[CRecordBatch]* out)

    CStatus AlignStream(CInputStream* stream, int64_t alignment)
    CStatus AlignStream(COutputStream* stream, int64_t alignment)

    cdef CStatus GetRecordBatchPayload\
        " arrow::ipc::internal::GetRecordBatchPayload"(
            const CRecordBatch& batch,
            const CIpcOptions& options,
            CMemoryPool* pool,
            CIpcPayload* out)

    cdef cppclass CFeatherWriter" arrow::ipc::feather::TableWriter":
        @staticmethod
        CStatus Open(const shared_ptr[COutputStream]& stream,
                     unique_ptr[CFeatherWriter]* out)

        void SetDescription(const c_string& desc)
        void SetNumRows(int64_t num_rows)

        CStatus Append(const c_string& name, const CArray& values)
        CStatus Finalize()

    cdef cppclass CFeatherReader" arrow::ipc::feather::TableReader":
        @staticmethod
        CStatus Open(const shared_ptr[CRandomAccessFile]& file,
                     unique_ptr[CFeatherReader]* out)

        c_string GetDescription()
        c_bool HasDescription()

        int64_t num_rows()
        int64_t num_columns()

        shared_ptr[CSchema] schema()

        CStatus GetColumn(int i, shared_ptr[CChunkedArray]* out)
        c_string GetColumnName(int i)

        CStatus Read(shared_ptr[CTable]* out)
        CStatus Read(const vector[int] indices, shared_ptr[CTable]* out)
        CStatus Read(const vector[c_string] names, shared_ptr[CTable]* out)


cdef extern from "arrow/csv/api.h" namespace "arrow::csv" nogil:

    cdef cppclass CCSVParseOptions" arrow::csv::ParseOptions":
        unsigned char delimiter
        c_bool quoting
        unsigned char quote_char
        c_bool double_quote
        c_bool escaping
        unsigned char escape_char
        c_bool newlines_in_values
        c_bool ignore_empty_lines

        @staticmethod
        CCSVParseOptions Defaults()

    cdef cppclass CCSVConvertOptions" arrow::csv::ConvertOptions":
        c_bool check_utf8
        unordered_map[c_string, shared_ptr[CDataType]] column_types
        vector[c_string] null_values
        vector[c_string] true_values
        vector[c_string] false_values
        c_bool strings_can_be_null

        c_bool auto_dict_encode
        int32_t auto_dict_max_cardinality

        vector[c_string] include_columns
        c_bool include_missing_columns

        @staticmethod
        CCSVConvertOptions Defaults()

    cdef cppclass CCSVReadOptions" arrow::csv::ReadOptions":
        c_bool use_threads
        int32_t block_size
        int32_t skip_rows
        vector[c_string] column_names
        c_bool autogenerate_column_names

        @staticmethod
        CCSVReadOptions Defaults()

    cdef cppclass CCSVReader" arrow::csv::TableReader":
        @staticmethod
        CStatus Make(CMemoryPool*, shared_ptr[CInputStream],
                     CCSVReadOptions, CCSVParseOptions, CCSVConvertOptions,
                     shared_ptr[CCSVReader]* out)

        CStatus Read(shared_ptr[CTable]* out)


cdef extern from "arrow/json/options.h" nogil:

    cdef cppclass CJSONReadOptions" arrow::json::ReadOptions":
        c_bool use_threads
        int32_t block_size

        @staticmethod
        CJSONReadOptions Defaults()

    cdef cppclass CJSONParseOptions" arrow::json::ParseOptions":
        shared_ptr[CSchema] explicit_schema
        c_bool newlines_in_values

        @staticmethod
        CJSONParseOptions Defaults()


cdef extern from "arrow/json/reader.h" namespace "arrow::json" nogil:

    cdef cppclass CJSONReader" arrow::json::TableReader":
        @staticmethod
        CStatus Make(CMemoryPool*, shared_ptr[CInputStream],
                     CJSONReadOptions, CJSONParseOptions,
                     shared_ptr[CJSONReader]* out)

        CStatus Read(shared_ptr[CTable]* out)

    cdef CStatus ParseOne(CJSONParseOptions options, shared_ptr[CBuffer] json,
                          shared_ptr[CRecordBatch]* out)


cdef extern from "arrow/compute/api.h" namespace "arrow::compute" nogil:

    cdef cppclass CFunctionContext" arrow::compute::FunctionContext":
        CFunctionContext()
        CFunctionContext(CMemoryPool* pool)

    cdef cppclass CCastOptions" arrow::compute::CastOptions":
        CCastOptions()
        CCastOptions(c_bool safe)
        CCastOptions Safe()
        CCastOptions Unsafe()
        c_bool allow_int_overflow
        c_bool allow_time_truncate
        c_bool allow_float_truncate

    cdef cppclass CTakeOptions" arrow::compute::TakeOptions":
        pass

    enum DatumType" arrow::compute::Datum::type":
        DatumType_NONE" arrow::compute::Datum::NONE"
        DatumType_SCALAR" arrow::compute::Datum::SCALAR"
        DatumType_ARRAY" arrow::compute::Datum::ARRAY"
        DatumType_CHUNKED_ARRAY" arrow::compute::Datum::CHUNKED_ARRAY"
        DatumType_RECORD_BATCH" arrow::compute::Datum::RECORD_BATCH"
        DatumType_TABLE" arrow::compute::Datum::TABLE"
        DatumType_COLLECTION" arrow::compute::Datum::COLLECTION"

    cdef cppclass CDatum" arrow::compute::Datum":
        CDatum()
        CDatum(const shared_ptr[CArray]& value)
        CDatum(const shared_ptr[CChunkedArray]& value)
        CDatum(const shared_ptr[CRecordBatch]& value)
        CDatum(const shared_ptr[CTable]& value)

        DatumType kind()

        shared_ptr[CArrayData] array()
        shared_ptr[CChunkedArray] chunked_array()
        shared_ptr[CScalar] scalar()

    CStatus Cast(CFunctionContext* context, const CArray& array,
                 const shared_ptr[CDataType]& to_type,
                 const CCastOptions& options,
                 shared_ptr[CArray]* out)

    CStatus Cast(CFunctionContext* context, const CDatum& value,
                 const shared_ptr[CDataType]& to_type,
                 const CCastOptions& options, CDatum* out)

    CStatus Unique(CFunctionContext* context, const CDatum& value,
                   shared_ptr[CArray]* out)

    CStatus DictionaryEncode(CFunctionContext* context, const CDatum& value,
                             CDatum* out)

    CStatus Sum(CFunctionContext* context, const CDatum& value, CDatum* out)

    CStatus Take(CFunctionContext* context, const CDatum& values,
                 const CDatum& indices, const CTakeOptions& options,
                 CDatum* out)

    # Filter clashes with gandiva.pyx::Filter
    CStatus FilterKernel" arrow::compute::Filter"(
        CFunctionContext* context, const CDatum& values,
        const CDatum& filter, CDatum* out)


cdef extern from "arrow/python/api.h" namespace "arrow::py":
    # Requires GIL
    CStatus InferArrowType(object obj, object mask,
                           c_bool pandas_null_sentinels,
                           shared_ptr[CDataType]* out_type)


cdef extern from "arrow/python/api.h" namespace "arrow::py" nogil:
    shared_ptr[CDataType] GetPrimitiveType(Type type)

    object PyHalf_FromHalf(npy_half value)

    cdef cppclass PyConversionOptions:
        PyConversionOptions()

        shared_ptr[CDataType] type
        int64_t size
        CMemoryPool* pool
        c_bool from_pandas

    # TODO Some functions below are not actually "nogil"

    CStatus ConvertPySequence(object obj, object mask,
                              const PyConversionOptions& options,
                              shared_ptr[CChunkedArray]* out)

    CStatus NumPyDtypeToArrow(object dtype, shared_ptr[CDataType]* type)

    CStatus NdarrayToArrow(CMemoryPool* pool, object ao, object mo,
                           c_bool from_pandas,
                           const shared_ptr[CDataType]& type,
                           shared_ptr[CChunkedArray]* out)

    CStatus NdarrayToArrow(CMemoryPool* pool, object ao, object mo,
                           c_bool from_pandas,
                           const shared_ptr[CDataType]& type,
                           const CCastOptions& cast_options,
                           shared_ptr[CChunkedArray]* out)

    CStatus NdarrayToTensor(CMemoryPool* pool, object ao,
                            const vector[c_string]& dim_names,
                            shared_ptr[CTensor]* out)

    CStatus TensorToNdarray(const shared_ptr[CTensor]& tensor, object base,
                            PyObject** out)

    CStatus SparseCOOTensorToNdarray(
        const shared_ptr[CSparseCOOTensor]& sparse_tensor, object base,
        PyObject** out_data, PyObject** out_coords)

    CStatus SparseCSRMatrixToNdarray(
        const shared_ptr[CSparseCSRMatrix]& sparse_tensor, object base,
        PyObject** out_data, PyObject** out_indptr, PyObject** out_indices)

    CStatus NdarraysToSparseCOOTensor(CMemoryPool* pool, object data_ao,
                                      object coords_ao,
                                      const vector[int64_t]& shape,
                                      const vector[c_string]& dim_names,
                                      shared_ptr[CSparseCOOTensor]* out)

    CStatus NdarraysToSparseCSRMatrix(CMemoryPool* pool, object data_ao,
                                      object indptr_ao, object indices_ao,
                                      const vector[int64_t]& shape,
                                      const vector[c_string]& dim_names,
                                      shared_ptr[CSparseCSRMatrix]* out)

    CStatus TensorToSparseCOOTensor(shared_ptr[CTensor],
                                    shared_ptr[CSparseCOOTensor]* out)

    CStatus TensorToSparseCSRMatrix(shared_ptr[CTensor],
                                    shared_ptr[CSparseCSRMatrix]* out)

    CStatus ConvertArrayToPandas(const PandasOptions& options,
                                 const shared_ptr[CArray]& arr,
                                 object py_ref, PyObject** out)

    CStatus ConvertChunkedArrayToPandas(const PandasOptions& options,
                                        const shared_ptr[CChunkedArray]& arr,
                                        object py_ref, PyObject** out)

    CStatus ConvertTableToPandas(
        const PandasOptions& options,
        const unordered_set[c_string]& categorical_columns,
        const unordered_set[c_string]& extension_columns,
        const shared_ptr[CTable]& table,
        PyObject** out)

    void c_set_default_memory_pool \
        " arrow::py::set_default_memory_pool"(CMemoryPool* pool)\

    CMemoryPool* c_get_memory_pool \
        " arrow::py::get_memory_pool"()

    cdef cppclass PyBuffer(CBuffer):
        @staticmethod
        CStatus FromPyObject(object obj, shared_ptr[CBuffer]* out)

    cdef cppclass PyForeignBuffer(CBuffer):
        @staticmethod
        CStatus Make(const uint8_t* data, int64_t size, object base,
                     shared_ptr[CBuffer]* out)

    cdef cppclass PyReadableFile(CRandomAccessFile):
        PyReadableFile(object fo)

    cdef cppclass PyOutputStream(COutputStream):
        PyOutputStream(object fo)

    cdef cppclass PandasOptions:
        CMemoryPool* pool
        c_bool strings_to_categorical
        c_bool zero_copy_only
        c_bool integer_object_nulls
        c_bool date_as_object
        c_bool use_threads
        c_bool deduplicate_objects

    cdef cppclass CSerializedPyObject" arrow::py::SerializedPyObject":
        shared_ptr[CRecordBatch] batch
        vector[shared_ptr[CTensor]] tensors

        CStatus WriteTo(COutputStream* dst)
        CStatus GetComponents(CMemoryPool* pool, PyObject** dst)

    CStatus SerializeObject(object context, object sequence,
                            CSerializedPyObject* out)

    CStatus DeserializeObject(object context,
                              const CSerializedPyObject& obj,
                              PyObject* base, PyObject** out)

    CStatus ReadSerializedObject(CRandomAccessFile* src,
                                 CSerializedPyObject* out)

    cdef cppclass SparseTensorCounts:
        SparseTensorCounts()
        int coo
        int csr
        int num_total_tensors() const
        int num_total_buffers() const

    CStatus GetSerializedFromComponents(
        int num_tensors,
        const SparseTensorCounts& num_sparse_tensors,
        int num_ndarrays,
        int num_buffers,
        object buffers,
        CSerializedPyObject* out)


cdef extern from "arrow/python/api.h" namespace "arrow::py::internal" nogil:

    cdef cppclass CTimePoint "arrow::py::internal::TimePoint":
        pass

    cdef CStatus PyDateTime_from_int(int64_t val, const TimeUnit unit,
                                     PyObject** out)
    cdef CStatus PyDateTime_from_TimePoint(CTimePoint val, PyObject** out)


cdef extern from 'arrow/python/init.h':
    int arrow_init_numpy() except -1


cdef extern from 'arrow/python/common.h' namespace "arrow::py":
    c_bool IsPyError(const CStatus& status)
    void RestorePyError(const CStatus& status)


cdef extern from 'arrow/python/pyarrow.h' namespace 'arrow::py':
    int import_pyarrow() except -1


cdef extern from 'arrow/python/config.h' namespace 'arrow::py':
    void set_numpy_nan(object o)


cdef extern from 'arrow/python/inference.h' namespace 'arrow::py':
    c_bool IsPyBool(object o)
    c_bool IsPyInt(object o)
    c_bool IsPyFloat(object o)


cdef extern from 'arrow/extension_type.h' namespace 'arrow':
    cdef cppclass CExtensionTypeRegistry" arrow::ExtensionTypeRegistry":
        @staticmethod
        shared_ptr[CExtensionTypeRegistry] GetGlobalRegistry()

    cdef cppclass CExtensionType" arrow::ExtensionType"(CDataType):
        c_string extension_name()
        shared_ptr[CDataType] storage_type()

    cdef cppclass CExtensionArray" arrow::ExtensionArray"(CArray):
        CExtensionArray(shared_ptr[CDataType], shared_ptr[CArray] storage)

        shared_ptr[CArray] storage()


cdef extern from 'arrow/python/extension_type.h' namespace 'arrow::py':
    cdef cppclass CPyExtensionType \
            " arrow::py::PyExtensionType"(CExtensionType):
        @staticmethod
        CStatus FromClass(const shared_ptr[CDataType] storage_type,
                          const c_string extension_name, object typ,
                          shared_ptr[CExtensionType]* out)

        @staticmethod
        CStatus FromInstance(shared_ptr[CDataType] storage_type,
                             object inst, shared_ptr[CExtensionType]* out)

        object GetInstance()
        CStatus SetInstance(object)

    c_string PyExtensionName()
    CStatus RegisterPyExtensionType(shared_ptr[CDataType])
    CStatus UnregisterPyExtensionType(c_string type_name)


cdef extern from 'arrow/python/benchmark.h' namespace 'arrow::py::benchmark':
    void Benchmark_PandasObjectIsNull(object lst) except *


cdef extern from 'arrow/util/compression.h' namespace 'arrow' nogil:
    enum CompressionType" arrow::Compression::type":
        CompressionType_UNCOMPRESSED" arrow::Compression::UNCOMPRESSED"
        CompressionType_SNAPPY" arrow::Compression::SNAPPY"
        CompressionType_GZIP" arrow::Compression::GZIP"
        CompressionType_BROTLI" arrow::Compression::BROTLI"
        CompressionType_ZSTD" arrow::Compression::ZSTD"
        CompressionType_LZ4" arrow::Compression::LZ4"
        CompressionType_BZ2" arrow::Compression::BZ2"

    cdef cppclass CCodec" arrow::util::Codec":
        @staticmethod
        CStatus Create(CompressionType codec, unique_ptr[CCodec]* out)

        CStatus Decompress(int64_t input_len, const uint8_t* input,
                           int64_t output_len, uint8_t* output_buffer)

        CStatus Compress(int64_t input_len, const uint8_t* input,
                         int64_t output_buffer_len, uint8_t* output_buffer,
                         int64_t* output_length)

        int64_t MaxCompressedLen(int64_t input_len, const uint8_t* input)


cdef extern from 'arrow/util/thread_pool.h' namespace 'arrow' nogil:
    int GetCpuThreadPoolCapacity()
    CStatus SetCpuThreadPoolCapacity(int threads)

cdef extern from 'arrow/array/concatenate.h' namespace 'arrow' nogil:
    CStatus Concatenate(const vector[shared_ptr[CArray]]& arrays,
                        CMemoryPool* pool, shared_ptr[CArray]* result)
