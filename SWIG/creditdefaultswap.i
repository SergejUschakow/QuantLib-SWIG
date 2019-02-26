/*
 Copyright (C) 2008, 2009 StatPro Italia srl
 Copyright (C) 2018 Matthias Lungwitz

 This file is part of QuantLib, a free-software/open-source library
 for financial quantitative analysts and developers - http://quantlib.org/

 QuantLib is free software: you can redistribute it and/or modify it
 under the terms of the QuantLib license.  You should have received a
 copy of the license along with this program; if not, please email
 <quantlib-dev@lists.sf.net>. The license is also available online at
 <http://quantlib.org/license.shtml>.

 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE.  See the license for more details.
*/

#ifndef quantlib_credit_default_swap_i
#define quantlib_credit_default_swap_i

%include instruments.i
%include credit.i
%include termstructures.i
%include bonds.i
%include null.i

%{
using QuantLib::CreditDefaultSwap;
using QuantLib::MidPointCdsEngine;
using QuantLib::IntegralCdsEngine;
using QuantLib::IsdaCdsEngine;
using QuantLib::Claim;
using QuantLib::FaceValueClaim;
using QuantLib::FaceValueAccrualClaim;

typedef boost::shared_ptr<PricingEngine> MidPointCdsEnginePtr;
typedef boost::shared_ptr<PricingEngine> IntegralCdsEnginePtr;
typedef boost::shared_ptr<PricingEngine> IsdaCdsEnginePtr;
typedef boost::shared_ptr<Claim> FaceValueClaimPtr;
typedef boost::shared_ptr<Claim> FaceValueAccrualClaimPtr;
%}

%shared_ptr(Claim);
class Claim {
  private:
    Claim();
  public:
    Real amount(const Date& defaultDate,
                Real notional,
                Real recoveryRate) const;
};

%shared_ptr(FaceValueClaim)
class FaceValueClaim : public Claim {
  public:
    FaceValueClaim();
};

%shared_ptr(FaceValueAccrualClaim)
class FaceValueAccrualClaim : public Claim {
  public:
    FaceValueAccrualClaim(const boost::shared_ptr<Bond>& bond);
};


%shared_ptr(CreditDefaultSwap)
class CreditDefaultSwap : public Instrument {
  public:
    enum PricingModel {
        Midpoint,
        ISDA
    };

    CreditDefaultSwap(Protection::Side side,
                         Real notional,
                         Rate spread,
                         const Schedule& schedule,
                         BusinessDayConvention paymentConvention,
                         const DayCounter& dayCounter,
                         bool settlesAccrual = true,
                         bool paysAtDefaultTime = true,
                         const Date& protectionStart = Date());
    CreditDefaultSwap(Protection::Side side,
                         Real notional,
                         Rate upfront,
                         Rate spread,
                         const Schedule& schedule,
                         BusinessDayConvention paymentConvention,
                         const DayCounter& dayCounter,
                         bool settlesAccrual = true,
                         bool paysAtDefaultTime = true,
                         const Date& protectionStart = Date(),
                         const Date& upfrontDate = Date(),
                         const boost::shared_ptr<Claim>& claim =
                                                    boost::shared_ptr<Claim>(),
                         const DayCounter& lastPeriodDayCounter = DayCounter(),
                         const bool rebatesAccrual = true);
    Protection::Side side() const;
    Real notional() const;
    Rate runningSpread() const;
    %extend {
    doubleOrNull upfront() const {
            boost::optional<Rate> result =
                self->upfront();
            if (result)
                return *result;
            else
                return Null<double>();
        }
    }
    bool settlesAccrual() const;
    bool paysAtDefaultTime() const;
    Rate fairSpread() const;
    Rate fairUpfront() const;
    Real couponLegBPS() const;
    Real couponLegNPV() const;
    Real defaultLegNPV() const;
    Real upfrontBPS() const;
    Real upfrontNPV() const;
    Rate impliedHazardRate(Real targetNPV,
                           const Handle<YieldTermStructure>& discountCurve,
                           const DayCounter& dayCounter,
                           Real recoveryRate = 0.4,
                           Real accuracy = 1.0e-6,
               CreditDefaultSwap::PricingModel model = CreditDefaultSwap::Midpoint) const;
    Rate conventionalSpread(Real conventionalRecovery,
            const Handle<YieldTermStructure>& discountCurve,
            const DayCounter& dayCounter) const;
    std::vector<boost::shared_ptr<CashFlow> > coupons();
};


%rename(MidPointCdsEngine) MidPointCdsEnginePtr;
class MidPointCdsEnginePtr : public boost::shared_ptr<PricingEngine> {
  public:
    %extend {
        MidPointCdsEnginePtr(
                   const Handle<DefaultProbabilityTermStructure>& probability,
                   Real recoveryRate,
                   const Handle<YieldTermStructure>& discountCurve) {
            return new MidPointCdsEnginePtr(
                              new MidPointCdsEngine(probability, recoveryRate,
                                                    discountCurve));
        }
    }
};

%rename(IntegralCdsEngine) IntegralCdsEnginePtr;
class IntegralCdsEnginePtr : public boost::shared_ptr<PricingEngine> {
  public:
    %extend {
        IntegralCdsEnginePtr(
				   const Period &integrationStep,
                   const Handle<DefaultProbabilityTermStructure>& probability,
                   Real recoveryRate,
                   const Handle<YieldTermStructure>& discountCurve,
				   bool includeSettlementDateFlows = false) {
            return new IntegralCdsEnginePtr(
                              new IntegralCdsEngine(integrationStep, probability,
                                                    recoveryRate, discountCurve,
													includeSettlementDateFlows));
        }
    }
};

#if defined(SWIGJAVA) || defined(SWIGCSHARP)
%rename(_IsdaCdsEngine) IsdaCdsEngine;
#else
%ignore IsdaCdsEngine;
#endif
class IsdaCdsEngine {
  public:
    enum NumericalFix {None, Taylor};
    enum AccrualBias {HalfDayBias, NoBias};
    enum ForwardsInCouponPeriod {Flat, Piecewise};
#if defined(SWIGJAVA) || defined(SWIGCSHARP)
  private:
    IsdaCdsEngine();
#endif
};

%rename(IsdaCdsEngine) IsdaCdsEnginePtr;
class IsdaCdsEnginePtr : public boost::shared_ptr<PricingEngine> {
    #if defined(SWIGPYTHON)
    %rename(NoFix) None;
    #endif
  public:
    %extend {
        static const IsdaCdsEngine::NumericalFix None = IsdaCdsEngine::None;
        static const IsdaCdsEngine::NumericalFix Taylor = IsdaCdsEngine::Taylor;
        static const IsdaCdsEngine::AccrualBias HalfDayBias = IsdaCdsEngine::HalfDayBias;
        static const IsdaCdsEngine::AccrualBias NoBias = IsdaCdsEngine::NoBias;
        static const IsdaCdsEngine::ForwardsInCouponPeriod Flat = IsdaCdsEngine::Flat;
        static const IsdaCdsEngine::ForwardsInCouponPeriod Piecewise = IsdaCdsEngine::Piecewise;
        IsdaCdsEnginePtr(
            const Handle<DefaultProbabilityTermStructure> &probability,
            Real recoveryRate,
            const Handle<YieldTermStructure> &discountCurve,
            bool includeSettlementDateFlows = false,
            const IsdaCdsEngine::NumericalFix numericalFix = IsdaCdsEngine::Taylor,
            const IsdaCdsEngine::AccrualBias accrualBias = IsdaCdsEngine::HalfDayBias,
            const IsdaCdsEngine::ForwardsInCouponPeriod forwardsInCouponPeriod = IsdaCdsEngine::Piecewise) {
            return new IsdaCdsEnginePtr(
                new IsdaCdsEngine(
                    probability,recoveryRate,discountCurve,includeSettlementDateFlows,numericalFix,accrualBias,forwardsInCouponPeriod));
        }
    }
};


#endif
