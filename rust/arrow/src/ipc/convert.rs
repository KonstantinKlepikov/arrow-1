// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

//! Utilities for converting between IPC types and native Arrow types

use crate::datatypes::{DataType, DateUnit, Field, Schema, TimeUnit};
use crate::ipc;

use flatbuffers::{
    FlatBufferBuilder, ForwardsUOffset, UnionWIPOffset, Vector, WIPOffset,
};

/// Serialize a schema in IPC format
fn schema_to_fb(schema: &Schema) -> FlatBufferBuilder {
    let mut fbb = FlatBufferBuilder::new();

    let mut fields = vec![];
    for field in schema.fields() {
        let fb_field_name = fbb.create_string(field.name().as_str());
        let (ipc_type_type, ipc_type, ipc_children) =
            get_fb_field_type(field.data_type(), &mut fbb);
        let mut field_builder = ipc::FieldBuilder::new(&mut fbb);
        field_builder.add_name(fb_field_name);
        field_builder.add_type_type(ipc_type_type);
        field_builder.add_nullable(field.is_nullable());
        match ipc_children {
            None => {}
            Some(children) => field_builder.add_children(children),
        };
        field_builder.add_type_(ipc_type);
        fields.push(field_builder.finish());
    }

    let fb_field_list = fbb.create_vector(&fields);

    let root = {
        let mut builder = ipc::SchemaBuilder::new(&mut fbb);
        builder.add_fields(fb_field_list);
        builder.finish()
    };

    fbb.finish(root, None);

    fbb
}

/// Convert an IPC Field to Arrow Field
impl<'a> From<ipc::Field<'a>> for Field {
    fn from(field: ipc::Field) -> Field {
        Field::new(
            field.name().unwrap(),
            get_data_type(field),
            field.nullable(),
        )
    }
}

/// Deserialize a Schema table from IPC format to Schema data type
pub fn fb_to_schema(fb: ipc::Schema) -> Schema {
    let mut fields: Vec<Field> = vec![];
    let c_fields = fb.fields().unwrap();
    let len = c_fields.len();
    for i in 0..len {
        let c_field: ipc::Field = c_fields.get(i);
        fields.push(c_field.into());
    }
    Schema::new(fields)
}

/// Get the Arrow data type from the flatbuffer Field table
fn get_data_type(field: ipc::Field) -> DataType {
    match field.type_type() {
        ipc::Type::Bool => DataType::Boolean,
        ipc::Type::Int => {
            let int = field.type_as_int().unwrap();
            match (int.bitWidth(), int.is_signed()) {
                (8, true) => DataType::Int8,
                (8, false) => DataType::UInt8,
                (16, true) => DataType::Int16,
                (16, false) => DataType::UInt16,
                (32, true) => DataType::Int32,
                (32, false) => DataType::UInt32,
                (64, true) => DataType::Int64,
                (64, false) => DataType::UInt64,
                _ => panic!("Unexpected bitwidth and signed"),
            }
        }
        ipc::Type::Binary => DataType::Binary,
        ipc::Type::Utf8 => DataType::Utf8,
        ipc::Type::FixedSizeBinary => {
            let fsb = field.type_as_fixed_size_binary().unwrap();
            DataType::FixedSizeBinary(fsb.byteWidth())
        }
        ipc::Type::FloatingPoint => {
            let float = field.type_as_floating_point().unwrap();
            match float.precision() {
                ipc::Precision::HALF => DataType::Float16,
                ipc::Precision::SINGLE => DataType::Float32,
                ipc::Precision::DOUBLE => DataType::Float64,
            }
        }
        ipc::Type::Date => {
            let date = field.type_as_date().unwrap();
            match date.unit() {
                ipc::DateUnit::DAY => DataType::Date32(DateUnit::Day),
                ipc::DateUnit::MILLISECOND => DataType::Date64(DateUnit::Millisecond),
            }
        }
        ipc::Type::Time => {
            let time = field.type_as_time().unwrap();
            match (time.bitWidth(), time.unit()) {
                (32, ipc::TimeUnit::SECOND) => DataType::Time32(TimeUnit::Second),
                (32, ipc::TimeUnit::MILLISECOND) => {
                    DataType::Time32(TimeUnit::Millisecond)
                }
                (64, ipc::TimeUnit::MICROSECOND) => {
                    DataType::Time64(TimeUnit::Microsecond)
                }
                (64, ipc::TimeUnit::NANOSECOND) => DataType::Time64(TimeUnit::Nanosecond),
                z @ _ => panic!(
                    "Time type with bit width of {} and unit of {:?} not supported",
                    z.0, z.1
                ),
            }
        }
        ipc::Type::Timestamp => {
            let timestamp = field.type_as_timestamp().unwrap();
            match timestamp.unit() {
                ipc::TimeUnit::SECOND => DataType::Timestamp(TimeUnit::Second),
                ipc::TimeUnit::MILLISECOND => DataType::Timestamp(TimeUnit::Millisecond),
                ipc::TimeUnit::MICROSECOND => DataType::Timestamp(TimeUnit::Microsecond),
                ipc::TimeUnit::NANOSECOND => DataType::Timestamp(TimeUnit::Nanosecond),
            }
        }
        ipc::Type::List => {
            let children = field.children().unwrap();
            if children.len() != 1 {
                panic!("expect a list to have one child")
            }
            let child_field = children.get(0);
            // returning int16 for now, to test, not sure how to get data type
            DataType::List(Box::new(get_data_type(child_field)))
        }
        ipc::Type::FixedSizeList => {
            let children = field.children().unwrap();
            if children.len() != 1 {
                panic!("expect a list to have one child")
            }
            let child_field = children.get(0);
            let fsl = field.type_as_fixed_size_list().unwrap();
            DataType::FixedSizeList((
                Box::new(get_data_type(child_field)),
                fsl.listSize(),
            ))
        }
        ipc::Type::Struct_ => {
            let mut fields = vec![];
            if let Some(children) = field.children() {
                for i in 0..children.len() {
                    fields.push(children.get(i).into());
                }
            };

            DataType::Struct(fields)
        }
        // TODO add interval support
        t @ _ => unimplemented!("Type {:?} not supported", t),
    }
}

/// Get the IPC type of a data type
fn get_fb_field_type<'a: 'b, 'b>(
    data_type: &DataType,
    mut fbb: &mut FlatBufferBuilder<'a>,
) -> (
    ipc::Type,
    WIPOffset<UnionWIPOffset>,
    Option<WIPOffset<Vector<'b, ForwardsUOffset<ipc::Field<'b>>>>>,
) {
    use DataType::*;
    match data_type {
        Boolean => (
            ipc::Type::Bool,
            ipc::BoolBuilder::new(&mut fbb).finish().as_union_value(),
            None,
        ),
        UInt8 | UInt16 | UInt32 | UInt64 => {
            let mut builder = ipc::IntBuilder::new(&mut fbb);
            builder.add_is_signed(false);
            match data_type {
                UInt8 => builder.add_bitWidth(8),
                UInt16 => builder.add_bitWidth(16),
                UInt32 => builder.add_bitWidth(32),
                UInt64 => builder.add_bitWidth(64),
                _ => {}
            };
            (ipc::Type::Int, builder.finish().as_union_value(), None)
        }
        Int8 | Int16 | Int32 | Int64 => {
            let mut builder = ipc::IntBuilder::new(&mut fbb);
            builder.add_is_signed(true);
            match data_type {
                Int8 => builder.add_bitWidth(8),
                Int16 => builder.add_bitWidth(16),
                Int32 => builder.add_bitWidth(32),
                Int64 => builder.add_bitWidth(64),
                _ => {}
            };
            (ipc::Type::Int, builder.finish().as_union_value(), None)
        }
        Float16 | Float32 | Float64 => {
            let mut builder = ipc::FloatingPointBuilder::new(&mut fbb);
            match data_type {
                Float16 => builder.add_precision(ipc::Precision::HALF),
                Float32 => builder.add_precision(ipc::Precision::SINGLE),
                Float64 => builder.add_precision(ipc::Precision::DOUBLE),
                _ => {}
            };
            (
                ipc::Type::FloatingPoint,
                builder.finish().as_union_value(),
                None,
            )
        }
        Utf8 => (
            ipc::Type::Utf8,
            ipc::Utf8Builder::new(&mut fbb).finish().as_union_value(),
            None,
        ),
        Date32(_) => {
            let mut builder = ipc::DateBuilder::new(&mut fbb);
            builder.add_unit(ipc::DateUnit::DAY);
            (ipc::Type::Date, builder.finish().as_union_value(), None)
        }
        Date64(_) => {
            let mut builder = ipc::DateBuilder::new(&mut fbb);
            builder.add_unit(ipc::DateUnit::MILLISECOND);
            (ipc::Type::Date, builder.finish().as_union_value(), None)
        }
        Time32(unit) | Time64(unit) => {
            let mut builder = ipc::TimeBuilder::new(&mut fbb);
            match unit {
                TimeUnit::Second => {
                    builder.add_bitWidth(32);
                    builder.add_unit(ipc::TimeUnit::SECOND);
                }
                TimeUnit::Millisecond => {
                    builder.add_bitWidth(32);
                    builder.add_unit(ipc::TimeUnit::MILLISECOND);
                }
                TimeUnit::Microsecond => {
                    builder.add_bitWidth(64);
                    builder.add_unit(ipc::TimeUnit::MICROSECOND);
                }
                TimeUnit::Nanosecond => {
                    builder.add_bitWidth(64);
                    builder.add_unit(ipc::TimeUnit::NANOSECOND);
                }
            }
            (ipc::Type::Time, builder.finish().as_union_value(), None)
        }
        Timestamp(unit) => {
            let mut builder = ipc::TimestampBuilder::new(&mut fbb);
            let time_unit = match unit {
                TimeUnit::Second => ipc::TimeUnit::SECOND,
                TimeUnit::Millisecond => ipc::TimeUnit::MILLISECOND,
                TimeUnit::Microsecond => ipc::TimeUnit::MICROSECOND,
                TimeUnit::Nanosecond => ipc::TimeUnit::NANOSECOND,
            };
            builder.add_unit(time_unit);
            (
                ipc::Type::Timestamp,
                builder.finish().as_union_value(),
                None,
            )
        }
        List(ref list_type) => {
            let inner_types = get_fb_field_type(list_type, &mut fbb);
            let child = ipc::Field::create(
                &mut fbb,
                &ipc::FieldArgs {
                    name: None,
                    nullable: false,
                    type_type: inner_types.0,
                    type_: Some(inner_types.1),
                    dictionary: None,
                    children: inner_types.2,
                    custom_metadata: None,
                },
            );
            let children = fbb.create_vector(&[child]);
            (
                ipc::Type::List,
                ipc::ListBuilder::new(&mut fbb).finish().as_union_value(),
                Some(children),
            )
        }
        Struct(fields) => {
            // struct's fields are children
            let mut children = vec![];
            for field in fields {
                let inner_types = get_fb_field_type(field.data_type(), &mut fbb);
                let field_name = fbb.create_string(field.name());
                children.push(ipc::Field::create(
                    &mut fbb,
                    &ipc::FieldArgs {
                        name: Some(field_name),
                        nullable: field.is_nullable(),
                        type_type: inner_types.0,
                        type_: Some(inner_types.1),
                        dictionary: None,
                        children: inner_types.2,
                        custom_metadata: None,
                    },
                ));
            }
            let children = fbb.create_vector(&children[..]);
            (
                ipc::Type::Struct_,
                ipc::Struct_Builder::new(&mut fbb).finish().as_union_value(),
                Some(children),
            )
        }
        t @ _ => panic!("Unsupported Arrow Data Type {:?}", t),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::datatypes::{DataType, Field, Schema};

    #[test]
    fn convert_schema_round_trip() {
        let schema = Schema::new(vec![
            Field::new("uint8", DataType::UInt8, false),
            Field::new("uint16", DataType::UInt16, true),
            Field::new("uint32", DataType::UInt32, false),
            Field::new("uint64", DataType::UInt64, true),
            Field::new("int8", DataType::Int8, true),
            Field::new("int16", DataType::Int16, false),
            Field::new("int32", DataType::Int32, true),
            Field::new("int64", DataType::Int64, false),
            Field::new("float16", DataType::Float16, true),
            Field::new("float32", DataType::Float32, false),
            Field::new("float64", DataType::Float64, true),
            Field::new("bool", DataType::Boolean, false),
            Field::new("date32", DataType::Date32(DateUnit::Day), false),
            Field::new("date64", DataType::Date64(DateUnit::Millisecond), true),
            Field::new("time32[s]", DataType::Time32(TimeUnit::Second), true),
            Field::new("time32[ms]", DataType::Time32(TimeUnit::Millisecond), false),
            Field::new("time64[us]", DataType::Time64(TimeUnit::Microsecond), false),
            Field::new("time64[ns]", DataType::Time64(TimeUnit::Nanosecond), true),
            Field::new("timestamp[s]", DataType::Timestamp(TimeUnit::Second), false),
            Field::new(
                "timestamp[ms]",
                DataType::Timestamp(TimeUnit::Millisecond),
                true,
            ),
            Field::new(
                "timestamp[us]",
                DataType::Timestamp(TimeUnit::Microsecond),
                false,
            ),
            Field::new(
                "timestamp[ns]",
                DataType::Timestamp(TimeUnit::Nanosecond),
                true,
            ),
            Field::new("utf8", DataType::Utf8, false),
            Field::new("list[u8]", DataType::List(Box::new(DataType::UInt8)), true),
            Field::new(
                "list[struct<float32, int32, bool>]",
                DataType::List(Box::new(DataType::Struct(vec![
                    Field::new("float32", DataType::UInt8, false),
                    Field::new("int32", DataType::Int32, true),
                    Field::new("bool", DataType::Boolean, true),
                ]))),
                false,
            ),
            Field::new(
                "struct<int64, list[struct<date32, list[struct<>]>]>",
                DataType::Struct(vec![
                    Field::new("int64", DataType::Int64, true),
                    Field::new(
                        "list[struct<date32, list[struct<>]>]",
                        DataType::List(Box::new(DataType::Struct(vec![
                            Field::new("date32", DataType::Date32(DateUnit::Day), true),
                            Field::new(
                                "list[struct<>]",
                                DataType::List(Box::new(DataType::Struct(vec![]))),
                                false,
                            ),
                        ]))),
                        false,
                    ),
                ]),
                false,
            ),
            Field::new("struct<>", DataType::Struct(vec![]), true),
        ]);

        let fb = schema_to_fb(&schema);

        // read back fields
        let ipc = ipc::get_root_as_schema(fb.finished_data());
        let schema2 = fb_to_schema(ipc);
        assert_eq!(schema, schema2);
    }
}
