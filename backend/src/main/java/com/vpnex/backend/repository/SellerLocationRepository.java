package com.vpnex.backend.repository;

import com.vpnex.backend.model.SellerLocation;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SellerLocationRepository extends JpaRepository<SellerLocation, String> {

  Optional<SellerLocation> findBySellerUid(String sellerUid);
}
