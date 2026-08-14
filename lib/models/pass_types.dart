import 'package:flutter/material.dart';
import 'package:wallet/l10n/app_localizations.dart';

enum PassCategory {
  retail('Retail'),
  tickets('Tickets & Transit'),
  access('Access'),
  health('Health'),
  identity('Identity'),
  generic('Generic');

  final String label;
  const PassCategory(this.label);

  /// Localized display label for this pass category.
  String localizedLabel(AppLocalizations l) {
    switch (this) {
      case PassCategory.retail:
        return l.passCategoryRetail;
      case PassCategory.tickets:
        return l.passCategoryTickets;
      case PassCategory.access:
        return l.passCategoryAccess;
      case PassCategory.health:
        return l.passCategoryHealth;
      case PassCategory.identity:
        return l.passCategoryIdentity;
      case PassCategory.generic:
        return l.passCategoryGeneric;
    }
  }
}

enum PassType {
  // Retail
  loyaltyCard('loyaltyCard', PassCategory.retail, 'Loyalty Card', Icons.card_membership_rounded),
  giftCard('giftCard', PassCategory.retail, 'Gift Card', Icons.card_giftcard_rounded),
  offer('offer', PassCategory.retail, 'Offer', Icons.local_offer_rounded),
  inStorePayment('inStorePayment', PassCategory.retail, 'In-Store Payment', Icons.contactless_rounded),

  // Tickets & Transit
  boardingPass('boardingPass', PassCategory.tickets, 'Boarding Pass', Icons.flight_rounded),
  eventTicket('eventTicket', PassCategory.tickets, 'Event Ticket', Icons.confirmation_number_rounded),
  transitPass('transitPass', PassCategory.tickets, 'Transit Pass', Icons.directions_bus_rounded),

  // Access
  digitalCarKey('digitalCarKey', PassCategory.access, 'Digital Car Key', Icons.directions_car_rounded),
  campusId('campusId', PassCategory.access, 'Campus ID', Icons.school_rounded),
  corporateBadge('corporateBadge', PassCategory.access, 'Corporate Badge', Icons.badge_rounded),
  hotelKey('hotelKey', PassCategory.access, 'Hotel Key', Icons.hotel_rounded),
  multiFamilyKey('multiFamilyKey', PassCategory.access, 'Multi-Family Key', Icons.apartment_rounded),

  // Health
  healthInsuranceCard('healthInsuranceCard', PassCategory.health, 'Health Insurance', Icons.health_and_safety_rounded),
  healthTestRecord('healthTestRecord', PassCategory.health, 'Test Record', Icons.science_rounded),
  healthVaccineCard('healthVaccineCard', PassCategory.health, 'Vaccine Card', Icons.vaccines_rounded),

  // Identity
  digitalCredential('digitalCredential', PassCategory.identity, 'Digital Credential', Icons.verified_user_rounded),

  // Generic
  generic('generic', PassCategory.generic, 'Generic', Icons.credit_card_rounded),
  genericPrivate('genericPrivate', PassCategory.generic, 'Private Pass', Icons.lock_rounded),

  // Legacy (kept for backward compatibility)
  coupon('coupon', PassCategory.retail, 'Coupon', Icons.local_offer_rounded),
  storeCard('storeCard', PassCategory.retail, 'Store Card', Icons.store_rounded);

  final String value;
  final PassCategory category;
  final String label;
  final IconData icon;
  const PassType(this.value, this.category, this.label, this.icon);

  static PassType fromValue(String? value) {
    if (value == null) return PassType.generic;
    for (final type in PassType.values) {
      if (type.value == value) return type;
    }
    return PassType.generic;
  }

  /// Localized display label for this pass type.
  String localizedLabel(AppLocalizations l) {
    switch (this) {
      case PassType.loyaltyCard:
        return l.passTypeLoyaltyCard;
      case PassType.giftCard:
        return l.passTypeGiftCard;
      case PassType.offer:
        return l.passTypeOffer;
      case PassType.inStorePayment:
        return l.passTypeInStorePayment;
      case PassType.boardingPass:
        return l.passTypeBoardingPass;
      case PassType.eventTicket:
        return l.passTypeEventTicket;
      case PassType.transitPass:
        return l.passTypeTransitPass;
      case PassType.digitalCarKey:
        return l.passTypeDigitalCarKey;
      case PassType.campusId:
        return l.passTypeCampusId;
      case PassType.corporateBadge:
        return l.passTypeCorporateBadge;
      case PassType.hotelKey:
        return l.passTypeHotelKey;
      case PassType.multiFamilyKey:
        return l.passTypeMultiFamilyKey;
      case PassType.healthInsuranceCard:
        return l.passTypeHealthInsurance;
      case PassType.healthTestRecord:
        return l.passTypeTestRecord;
      case PassType.healthVaccineCard:
        return l.passTypeVaccineCard;
      case PassType.digitalCredential:
        return l.passTypeDigitalCredential;
      case PassType.generic:
        return l.passTypeGeneric;
      case PassType.genericPrivate:
        return l.passTypeGenericPrivate;
      case PassType.coupon:
        return l.passTypeCoupon;
      case PassType.storeCard:
        return l.passTypeStoreCard;
    }
  }
}

/// Returns the display label for a given pass type string.
String getPassTypeLabel(String type) {
  return PassType.fromValue(type).label;
}

/// Returns the localized display label for a given pass type string.
String getLocalizedPassTypeLabel(String type, AppLocalizations l) {
  return PassType.fromValue(type).localizedLabel(l);
}
