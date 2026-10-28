package com.vpnex.backend.repository;

import com.vpnex.backend.model.SellerBankDetails;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SellerBankDetailsRepository extends JpaRepository<SellerBankDetails, String> {

  Optional<SellerBankDetails> findBySellerUid(String sellerUid);

  boolean existsBySellerUidAndIfscVerifiedTrue(String sellerUid);
}
