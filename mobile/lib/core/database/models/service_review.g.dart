// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

part of 'service_review.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetServiceReviewCollection on Isar {
  IsarCollection<ServiceReview> get serviceReviews => this.collection();
}

const ServiceReviewSchema = CollectionSchema(
  name: r'ServiceReview',
  id: 3841027659432187654,
  properties: {
    r'category': PropertySchema(
      id: 0,
      name: r'category',
      type: IsarType.string,
    ),
    r'comment': PropertySchema(
      id: 1,
      name: r'comment',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'isAnonymous': PropertySchema(
      id: 3,
      name: r'isAnonymous',
      type: IsarType.bool,
    ),
    r'rating': PropertySchema(
      id: 4,
      name: r'rating',
      type: IsarType.long,
    ),
    r'serviceId': PropertySchema(
      id: 5,
      name: r'serviceId',
      type: IsarType.string,
    ),
    r'serviceName': PropertySchema(
      id: 6,
      name: r'serviceName',
      type: IsarType.string,
    ),
    r'serviceType': PropertySchema(
      id: 7,
      name: r'serviceType',
      type: IsarType.string,
    ),
  },
  estimateSize: _serviceReviewEstimateSize,
  serialize: _serviceReviewSerialize,
  deserialize: _serviceReviewDeserialize,
  deserializeProp: _serviceReviewDeserializeProp,
  idName: r'id',
  indexes: {
    r'serviceId': IndexSchema(
      id: 2748694610347548900,
      name: r'serviceId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'serviceId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'serviceType': IndexSchema(
      id: 1927384650192837465,
      name: r'serviceType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'serviceType',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'createdAt': IndexSchema(
      id: 5638291047382910562,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _serviceReviewGetId,
  getLinks: _serviceReviewGetLinks,
  attach: _serviceReviewAttach,
  version: '3.1.0+1',
);

int _serviceReviewEstimateSize(
  ServiceReview object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.category.length * 3;
  bytesCount += 3 + object.comment.length * 3;
  bytesCount += 3 + object.serviceId.length * 3;
  bytesCount += 3 + object.serviceName.length * 3;
  bytesCount += 3 + object.serviceType.length * 3;
  return bytesCount;
}

void _serviceReviewSerialize(
  ServiceReview object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.category);
  writer.writeString(offsets[1], object.comment);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeBool(offsets[3], object.isAnonymous);
  writer.writeLong(offsets[4], object.rating);
  writer.writeString(offsets[5], object.serviceId);
  writer.writeString(offsets[6], object.serviceName);
  writer.writeString(offsets[7], object.serviceType);
}

ServiceReview _serviceReviewDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ServiceReview();
  object.category = reader.readString(offsets[0]);
  object.comment = reader.readString(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.id = id;
  object.isAnonymous = reader.readBool(offsets[3]);
  object.rating = reader.readLong(offsets[4]);
  object.serviceId = reader.readString(offsets[5]);
  object.serviceName = reader.readString(offsets[6]);
  object.serviceType = reader.readString(offsets[7]);
  return object;
}

P _serviceReviewDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _serviceReviewGetId(ServiceReview object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _serviceReviewGetLinks(ServiceReview object) {
  return [];
}

void _serviceReviewAttach(
    IsarCollection<dynamic> col, Id id, ServiceReview object) {
  object.id = id;
}

extension ServiceReviewQueryWhere
    on QueryBuilder<ServiceReview, ServiceReview, QWhereClause> {
  QueryBuilder<ServiceReview, ServiceReview, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply<ServiceReview, ServiceReview, QAfterWhereClause>(
        this, (query) {
      return query
          .addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ServiceReview, ServiceReview, QAfterWhereClause>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }
}

extension ServiceReviewQueryFilter
    on QueryBuilder<ServiceReview, ServiceReview, QFilterCondition> {
  QueryBuilder<ServiceReview, ServiceReview, QAfterFilterCondition>
      serviceIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ServiceReview, ServiceReview, QAfterFilterCondition>
      serviceTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serviceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ServiceReview, ServiceReview, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        upper: upper,
        includeLower: includeLower,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ServiceReviewQuerySortBy
    on QueryBuilder<ServiceReview, ServiceReview, QSortBy> {
  QueryBuilder<ServiceReview, ServiceReview, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ServiceReview, ServiceReview, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ServiceReview, ServiceReview, QAfterSortBy> sortByServiceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceId', Sort.asc);
    });
  }

  QueryBuilder<ServiceReview, ServiceReview, QAfterSortBy> sortByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.asc);
    });
  }
}

extension ServiceReviewQueryObject
    on QueryBuilder<ServiceReview, ServiceReview, QQueryOperations> {}
