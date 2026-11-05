package com.vpnex.backend.repository;

import com.vpnex.backend.model.Seller;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SellerRepository extends JpaRepository<Seller, String> {

  Optional<Seller> findByPhone(String phone);

  boolean existsByEmail(String email);
}
