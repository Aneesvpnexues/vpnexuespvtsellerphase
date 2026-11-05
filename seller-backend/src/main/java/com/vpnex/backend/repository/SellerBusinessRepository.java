package com.vpnex.backend.repository;

import com.vpnex.backend.model.SellerBusiness;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SellerBusinessRepository extends JpaRepository<SellerBusiness, String> {

  Optional<SellerBusiness> findBySellerUid(String sellerUid);
}
