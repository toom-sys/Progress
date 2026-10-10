//
//  MembershipPricingTests.swift
//  ProgressTests
//

import Testing
@testable import Progress

struct MembershipPricingTests {

    @Test func cataloguePricesMatchTheMembership() {
        #expect(MembershipPricing.weekly == Decimal(string: "4.99"))
        #expect(MembershipPricing.monthly == Decimal(string: "9.99"))
        #expect(MembershipPricing.yearly == Decimal(string: "49.99"))
    }

    @Test func yearlyIsCheaperThanTwelveMonths() {
        let yearOfMonthly = MembershipPricing.costOfPayingMonthlyForAYear
        #expect(yearOfMonthly == Decimal(string: "119.88"))
        #expect(yearOfMonthly - MembershipPricing.yearly == Decimal(string: "69.89"))
    }

    @Test func yearlyEquivalentMonthRoundsToFourPoundsSeventeen() {
        let formatted = MembershipPricing.format(MembershipPricing.yearlyEquivalentPerMonth)
        #expect(formatted == "£4.17")
    }

    @Test func paywallLeadsWithTheYear() {
        #expect(MembershipPeriod.paywallOrder.first == .yearly)
        #expect(MembershipPeriod.yearly.productIdentifier == "com.tom.progress.member.yearly")
        #expect(MembershipPeriod.monthly.productIdentifier == "com.tom.progress.member.monthly")
        #expect(MembershipPeriod.weekly.productIdentifier == "com.tom.progress.member.weekly")
    }

    @Test func legacyTierValuesAreNotMembers() throws {
        let standard = try JSONDecoder().decode(SubscriptionTier.self, from: Data("\"standard\"".utf8))
        let plusAI = try JSONDecoder().decode(SubscriptionTier.self, from: Data("\"plus_ai\"".utf8))
        let member = try JSONDecoder().decode(SubscriptionTier.self, from: Data("\"member\"".utf8))

        #expect(standard == .none)
        #expect(plusAI == .none)
        #expect(member == .member)
    }
}
